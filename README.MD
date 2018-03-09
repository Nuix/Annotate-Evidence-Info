

Annotate Evidence Info
===============

![Last tested in Nuix 7.4](https://img.shields.io/badge/Nuix-7.4-green.svg)

View the GitHub project [here](https://github.com/NuixSDK/Annotate-Evidence-Info) or download the latest release [here](https://github.com/NuixSDK/Annotate-Evidence-Info/releases).

# Overview

**Written By:** Jason Wells

This script takes information from evidence container items and applies it as custom metadata to the descendant items of that evidence container.  Values which can be applied:
- Source Charset
- Source Time Zone
- Name
- Sources (the evidence source paths ingested when the evidence was created)

The script allows you to run this against all evidence containers or a selection of evidence containers.

# Getting Started

## Setup

Begin by downloading the latest release.  Extract the contents of the archive into your Nuix scripts directory.  In Windows the script directory is likely going to be either of the following:

- `%appdata%\Nuix\Scripts` - User level script directory
- `%programdata%\Nuix\Scripts` - System level script directory

## Settings

| Setting | Description |
|---------|-------------|
| **Apply Evidence Charset** | When checked, descendants of a given evidence item will have the value of the `Source Charset` property of the ancestor evidence item applied as custom metadata. |
| **Charset Custom Field** | The name of the custom metadata field to use. |
| **Apply Evidence Time Zone** | When checked, descendants of a given evidence item will have the value of the `Source Time Zone` property of the ancestor evidence item applied as custom metadata. |
| **Time Zone Custom Field** | The name of the custom metadata field to use. |
| **Apply Evidence Name** | When checked, descendants of a given evidence item will have the value of the `Name` of the ancestor evidence item applied as custom metadata. |
| **Name Custom Field** | The name of the custom metadata field to use. |
| **Apply Evidence Sources** | When checked, descendants of a given evidence item will have the source paths used to create the given evidence applied as a custom metadata field.  Values are parsed from the evidence XML files.  For evidence which was added using multiple source paths the value in this field will be delimited by semicolons (`;`). |
| **Sources Custom Field** | The name of the custom metadata field to use. |
| **All Evidence** | When checked, all evidence in the current case will be processed. |
| **Specific Evidence** | When checked, only the evidence items you select will be processed. |

# License

```
Copyright 2018 Nuix

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```