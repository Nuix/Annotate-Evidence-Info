script_directory = File.dirname(__FILE__)
require File.join(script_directory,"Nx.jar")
java_import "com.nuix.nx.NuixConnection"
java_import "com.nuix.nx.LookAndFeelHelper"
java_import "com.nuix.nx.dialogs.ChoiceDialog"
java_import "com.nuix.nx.dialogs.TabbedCustomDialog"
java_import "com.nuix.nx.dialogs.CommonDialogs"
java_import "com.nuix.nx.dialogs.ProgressDialog"
java_import "com.nuix.nx.dialogs.ProcessingStatusDialog"
java_import "com.nuix.nx.digest.DigestHelper"
java_import "com.nuix.nx.controls.models.Choice"

LookAndFeelHelper.setWindowsIfMetal
NuixConnection.setUtilities($utilities)
NuixConnection.setCurrentNuixVersion(NUIX_VERSION)

# Code to parse evidence XML files in the current case to locate details regarding
# the source paths the user selected when creating a particular evidence container
require 'rexml/document'
def get_evidence_sources
	result = Hash.new{|h,k|h[k]=[]}
	case_root = $current_case.getLocation.getAbsolutePath
	evidence_directory = "#{case_root}\\Stores\\Evidence"
	jdir = java.io.File.new(evidence_directory)
	file_list = jdir.listFiles
	if file_list.nil? == false
		file_list.map{|f|f.getAbsolutePath}.each do |file|
			if file =~ /\.xml$/i
				xml_data = ""
				File.open(file,"r") do |f|
					xml_data = f.read
				end
				doc = REXML::Document.new(xml_data)
				name = nil
				doc.elements.each('evidence/name') do |ele|
					name = ele.text
				end
				doc.elements.each('evidence/data-roots/data-root/*') do |ele|
					result[name] << ele.attributes["location"]
				end
			end
		end
	end
	return result
end

# Get a list of evidence items in the case
evidence_item_choices = $current_case.getRootItems.map{|i|Choice.new(i,i.getLocalisedName)}

# Build settings dialog
dialog = TabbedCustomDialog.new("Annotate Evidence Info")
dialog.enableStickySettings(File.join(script_directory,"RecentSettings.json"))

main_tab = dialog.addTab("main","Main")
main_tab.appendCheckBox("apply_charset","Apply Evidence Charset",true)
main_tab.appendTextField("charset_field","Charset Custom Field","Evidence Source Charset")
main_tab.enabledOnlyWhenChecked("charset_field","apply_charset")

main_tab.appendCheckBox("apply_time_zone","Apply Evidence Time Zone",true)
main_tab.appendTextField("time_zone_field","Time Zone Custom Field","Evidence Source Time Zone")
main_tab.enabledOnlyWhenChecked("time_zone_field","apply_time_zone")

main_tab.appendCheckBox("apply_name","Apply Evidence Name",true)
main_tab.appendTextField("name_field","Name Custom Field","Evidence Name")
main_tab.enabledOnlyWhenChecked("name_field","apply_name")

main_tab.appendCheckBox("apply_sources","Apply Evidence Sources",true)
main_tab.appendTextField("sources_field","Sources Custom Field","Evidence Sources")
main_tab.enabledOnlyWhenChecked("sources_field","apply_sources")

main_tab.appendRadioButton("all_evidence","All Evidence","evidence_input_group",true)
main_tab.appendRadioButton("specific_evidence","Specific Evidence","evidence_input_group",false)
main_tab.appendChoiceTable("selected_evidence_items","Selected Evidence",evidence_item_choices)
main_tab.enabledOnlyWhenChecked("selected_evidence_items","specific_evidence")

# Define validations for user settings
dialog.validateBeforeClosing do |values|
	if !values["apply_charset"] && !values["apply_time_zone"] && !values["apply_name"] && !values["apply_sources"]
		CommonDialogs.showError("Please check at least one type to apply.")
		next false
	end

	if values["apply_charset"] && values["charset_field"].strip.empty?
		CommonDialogs.showError("'Charset Custom Field' cannot be blank.")
		next false
	end

	if values["apply_time_zone"] && values["time_zone_field"].strip.empty?
		CommonDialogs.showError("'Time Zone Custom Field' cannot be blank.")
		next false
	end

	if values["apply_name"] && values["name_field"].strip.empty?
		CommonDialogs.showError("'Name Custom Field' cannot be blank.")
		next false
	end

	if values["apply_sources"] && values["sources_field"].strip.empty?
		CommonDialogs.showError("'Sources Custom Field' cannot be blank.")
		next false
	end

	if values["specific_evidence"] && values["selected_evidence_items"].size < 1
		CommonDialogs.showError("You must check at least one evidence item when 'Specific Evidence' is checked.")
		next false
	end

	next true
end

# Display settings dialog, if everything works out with that we will
# proceed with processing
dialog.display
if dialog.getDialogResult == true

	# Show a progress dialog while we do the work
	ProgressDialog.forBlock do |pd|
		pd.setTitle("Annotate Evidence Info")
		pd.setAbortButtonVisible(false)

		# Get settings from settings dialog
		values = dialog.toMap

		# Store settings into variables for convenience
		apply_charset = values["apply_charset"]
		apply_time_zone = values["apply_time_zone"]
		apply_name = values["apply_name"]
		apply_sources = values["apply_sources"]
		charset_field = values["charset_field"]
		time_zone_field = values["time_zone_field"]
		name_field = values["name_field"]
		sources_field = values["sources_field"]

		evidence_items = nil
		all_evidence_sources = nil

		if values["specific_evidence"]
			evidence_items = values["selected_evidence_items"]
		else
			pd.setMainStatusAndLogIt("Locating evidence items...")
			evidence_items = $current_case.getRootItems
			pd.logMessage("Located #{evidence_items.size} evidence items")
		end

		if apply_sources
			pd.setMainStatusAndLogIt("Determining evidence sources...")
			all_evidence_sources = get_evidence_sources
		end

		iutil = $utilities.getItemUtility
		annotater = $utilities.getBulkAnnotater
		last_progress = Time.now

		# Iterate each evidence item we will be annotating the descendants of
		pd.setMainProgress(0,evidence_items.size)
		evidence_items.each_with_index do |evidence_item,evidence_index|
			pd.setMainStatus("Processing Evidence (#{evidence_index+1}/#{evidence_items.size}) : #{evidence_item.getLocalisedName}")
			pd.logMessage("=== Processing Evidence (#{evidence_index+1}/#{evidence_items.size}) : #{evidence_item.getLocalisedName} ===")
			pd.setMainProgress(evidence_index+1)
			
			evidence_properties = evidence_item.getProperties
			evidence_charset = evidence_properties["Source Charset"]
			evidence_time_zone = evidence_properties["Source Time Zone"]
			evidence_name = evidence_item.getLocalisedName

			pd.logMessage("Name: #{evidence_name}")
			pd.logMessage("Charset: #{evidence_charset}")
			pd.logMessage("Time Zone: #{evidence_time_zone}")

			# Determine and annotate evidence sources
			evidence_sources = nil
			if apply_sources
				evidence_sources = all_evidence_sources[evidence_item.getLocalisedName].join(";")
				pd.logMessage("Sources: #{evidence_sources}")
			end

			# Obtain the descendant items of the current evidence container item
			pd.setSubStatusAndLogIt("Locating descendants...")
			evidence_descendants = iutil.findDescendants(Array(evidence_item))
			pd.logMessage("Located #{evidence_descendants.size} descendant items")

			# Annotate evidence container charset to descendants
			if apply_charset
				pd.logMessage("Applying charset...")
				pd.setSubProgress(0,evidence_descendants.size)
				# Annotate with progress updates
				annotater.putCustomMetadata(charset_field,evidence_charset,evidence_descendants) do |info|
					if (Time.now - last_progress) > 0.25
						pd.setSubStatus("Applying '#{charset_field}' (#{info.getStageCount}/#{evidence_descendants.size})")
						pd.setSubProgress(info.getStageCount)
						last_progress = Time.now
					end
				end
				pd.setSubProgress(1,1)
				pd.logMessage("Charset applied")
			end

			# Annotate evidence container time zone to descendants
			if apply_time_zone
				pd.logMessage("Applying time zone...")
				pd.setSubProgress(0,evidence_descendants.size)
				# Annotate with progress updates
				annotater.putCustomMetadata(time_zone_field,evidence_time_zone,evidence_descendants) do |info|
					if (Time.now - last_progress) > 0.25
						pd.setSubStatus("Applying '#{time_zone_field}' (#{info.getStageCount}/#{evidence_descendants.size})")
						pd.setSubProgress(info.getStageCount)
						last_progress = Time.now
					end
				end
				pd.setSubProgress(1,1)
				pd.logMessage("Time zone applied")
			end

			# Annotate evidence container name to descendants
			if apply_name
				pd.logMessage("Applying evidence name...")
				pd.setSubProgress(0,evidence_descendants.size)
				# Annotate with progress updates
				annotater.putCustomMetadata(name_field,evidence_name,evidence_descendants) do |info|
					if (Time.now - last_progress) > 0.25
						pd.setSubStatus("Applying '#{name_field}' (#{info.getStageCount}/#{evidence_descendants.size})")
						pd.setSubProgress(info.getStageCount)
						last_progress = Time.now
					end
				end
				pd.setSubProgress(1,1)
				pd.logMessage("Evidence name applied")
			end

			# # Annotate evidence container sources to descendants
			if apply_sources
				pd.logMessage("Applying evidence sources...")
				pd.setSubProgress(0,evidence_descendants.size)
				# Annotate with progress updates
				annotater.putCustomMetadata(sources_field,evidence_sources,evidence_descendants) do |info|
					if (Time.now - last_progress) > 0.25
						pd.setSubStatus("Applying '#{sources_field}' (#{info.getStageCount}/#{evidence_descendants.size})")
						pd.setSubProgress(info.getStageCount)
						last_progress = Time.now
					end
				end
				pd.setSubProgress(1,1)
				pd.logMessage("Evidence sources applied")
			end
		end

		# Put progress dialog into a completed state
		pd.setCompleted
	end
end