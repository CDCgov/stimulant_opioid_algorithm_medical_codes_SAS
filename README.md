# Guide to the Medical Code Component <p> of the NCHS Stimulant and Opioid Use Algorithm

**Author: Minchan (Daisy) Shi**

**sse6@cdc.gov**

**Edited: November 14, 2024**

## Overview

<ins> Background </ins>

The code contained in this repository is part of a project titled “Utilizing Natural Language Processing and Machine Learning to Enhance the Identification of Stimulant and Opioid-Involved Health Outcomes in the National Hospital Care Survey,” which was funded by the Office of the Secretary – Patient-Centered Outcomes Research Trust Fund in the 2023 fiscal year. This work was carried out by the National Center for Health Statistics (NCHS) using data from the 2020 National Hospital Care Survey. The full algorithm has two primary components: a natural language processing component and a medical code-based component. This R code covers the medical code-based component.

This algorithm uses medical codes (for example, diagnoses or procedure codes) to identify hospital encounters involving the non-therapeutic use of stimulants and opioids. Non-therapeutic use includes the use of illicit substances (stimulants or opioids), misuse of prescriptions, or the unspecified non-therapeutic use of substances. The algorithm is designed to analyze data in table form and produce an output file containing variables related to non-therapeutic stimulant use, non-therapeutic opioid use, and the co-occurrence (a proxy for co-use) of these two types of use. 

The natural language processing component for this algorithm designed to analyze clinical notes is in the following repository:

  * https://github.com/CDCgov/stimulant_opioid_algorithm_clinical_notes

<ins>Related repositories:</ins>

The stimulant algorithm is the third in a series of related substance-use-related algorithms. For your reference, these algorithms can be found in the following repositories.

  * [ ] Algorithm to detect opioid use, selected mental health issues, and substance use disorders in medical codes: 
    * https://github.com/CDCgov/Opioid_SUD_MHI_MedCodes

  * [ ] Algorithms to detect opioid use, selected mental health issues, and substance use disorders in clinical notes: 
    * https://github.com/CDCgov/Opioid_Involvement_NLP
    * https://github.com/CDCgov/SUD_MHI_NLP

<ins>Usage </ins>

The ‘create_output_table’ macro is the key component of this algorithm. It generates an output table of medical records identified for having stimulant or opioid use involvement based on mapping rules defined in an external Excel file ("Code_Mapping_GitHub.xlsx") called in the macro. The Excel file maps medical codes to different types of stimulant use or opioid use. The macro applies the mapping rules in the Excel file to categorize and filter input data (coded medical data) for patterns of non-therapeutic stimulant use, opioid use, and other related health outcomes; it also derives a variable for co-use based on the detection of both opioid and stimulant use in the same medical record. The macro handles various types of input data (CSV, Excel, SAS, database, or preloaded data). The rest of this readme file provides detailed explanations of each parameter called in the ‘create_output_table’ macro and examples of usage scenarios. 

Depending on the analyst’s needs, the algorithm can be tailored to fit different use cases or augmented to increase applicability. Adjust the examples and details as necessary to match your specific use case. Ensure that your input data includes a column for the code formatted according to the "Code_Mapping_GitHub.xlsx" file. Your code column should match the format specified in that file.

## Macro Parameters

### code_mapping_file

Description: Path to the code mapping Excel file `Code_Mapping_GitHub.xlsx,` which contains medical codes mapped to output variables, and is provided in this repository.  To run the ‘create_output_table’ macro, specify the location (path) where you saved the file. 

Example (do not enclose in quotes):

    code_mapping_file=path_to/Code_Mapping_GitHub.xlsx

### code_system_name

Description: Name of the medical code system to subset the code mapping file by. Users can choose from 'ICD-10-CM', 'HCPCS', 'RXNORM', 'SNOMED', 'LOINC', or NULL (not specifying any code system).

Examples: 

    code_system_name = "ICD-10-CM" (use quotes, unless you entry is NULL)
    Code_sytem_name= "HCPCS", “ICD-1 0-CM” (more than one system allowed, in quotes, separated by commas)

### dataType

Description: Type of input data. Supported types include  'csv', 'xlsx', 'sas', or 'preloaded_data'.

Example (enter only ONE format): 

    dataType = csv 
    dataType = xlsx

### inputPath

Description: Path to the folder where the input file (the coded medical data file to be searched) is located.  Provide `NULL` if dataType is 'preloaded_data'.

Examples (path does not need to be in quotes): 

    inputPath = C:\Users\sse6\Desktop\Github   
    Inputpath= NULL 

### inputFileName

Description: Name of the input file (the coded medical data file to be searched).  

Example (enter your input file. This is the sample file provided): 

    inputFIleName = fake_data 

### columns_to_keep

Description: Columns to include in the output table.

Example (separated by spaces, no quotes or commas needed): 

    columns_to_keep = ID  VisitType 

### output_table_name  

Description: Name of your output file. The output is only available in SAS format. 

Example: 

    output_table_name= results_file

### code

Description: Name of the column name (variable) containing medical codes in the input data (coded medical record data). Only one variable or column name is allowed. 

Example (this example is the variable name in the sample input data provided): 

    Code= Code 

### codesys_name  (optional)

Description: The column name (variable) in your input data set, containing the names of the medical code system types for the medical codes in variable containing medical codes (parameter ‘code’). Allows user to subset the input data by a specific medical code system type. Enter NULL if you do not want to filter rows of the input data based on the specified condition, or if the parameter ‘code_system_name’ is not set to NULL. 

Example (this example is a variable in the sample input data provided): 

    codesys_name =  CodeType  

Note: The codes for the included code systems are intended to search for the following types of information:

| Code System |	Information Type |
| ------ | ------ | 
| ICD-10-CM |	Diagnoses |
| SNOMED	| Diagnoses |
| HCPCS |	Procedures |
| RXNORM |	Medications |
| LOINC |	Labs |

### searching_text (optional)

Description: Subsets rows of the input data based on a specified medical code system type. These are the values in the column name (variable) specified in the 'codesys_name' parameter above. If 'codesys_name' is NULL, then 'searching_text' should also be NULL. Enter NULL if you do not want to filter rows of the input data based on a medical code system, or if the parameter ‘code_system_name’ is NOT set to NULL.

Example (use quotes unless using NULL): 

    searching_text = "ICD-10-CM" 


## Public Domain Standard Notice
This repository constitutes a work of the United States Government and is not
subject to domestic copyright protection under 17 USC § 105. This repository is in
the public domain within the United States, and copyright and related rights in
the work worldwide are waived through the [CC0 1.0 Universal public domain dedication](https://creativecommons.org/publicdomain/zero/1.0/).
All contributions to this repository will be released under the CC0 dedication. By
submitting a pull request you are agreeing to comply with this waiver of
copyright interest.

## License Standard Notice
The repository utilizes code licensed under the terms of the Apache Software
License and therefore is licensed under ASL v2 or later.

This source code in this repository is free: you can redistribute it and/or modify it under
the terms of the Apache Software License version 2, or (at your option) any
later version.

This source code in this repository is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE. See the Apache Software License for more details.

You should have received a copy of the Apache Software License along with this
program. If not, see http://www.apache.org/licenses/LICENSE-2.0.html

The source code forked from other open source projects will inherit its license.

## Privacy Standard Notice
This repository contains only non-sensitive, publicly available data and
information. All material and community participation is covered by the
[Disclaimer](DISCLAIMER.md)
and [Code of Conduct](code-of-conduct.md).
For more information about CDC's privacy policy, please visit [http://www.cdc.gov/other/privacy.html](https://www.cdc.gov/other/privacy.html).

## Contributing Standard Notice
Anyone is encouraged to contribute to the repository by [forking](https://help.github.com/articles/fork-a-repo)
and submitting a pull request. (If you are new to GitHub, you might start with a
[basic tutorial](https://help.github.com/articles/set-up-git).) By contributing
to this project, you grant a world-wide, royalty-free, perpetual, irrevocable,
non-exclusive, transferable license to all users under the terms of the
[Apache Software License v2](http://www.apache.org/licenses/LICENSE-2.0.html) or
later.

All comments, messages, pull requests, and other submissions received through
CDC including this GitHub page may be subject to applicable federal law, including but not limited to the Federal Records Act, and may be archived. Learn more at [http://www.cdc.gov/other/privacy.html](http://www.cdc.gov/other/privacy.html).

## Records Management Standard Notice
This repository is not a source of government records, but is a copy to increase
collaboration and collaborative potential. All government records will be
published through the [CDC web site](http://www.cdc.gov).

## Additional Standard Notices
Please refer to [CDC's Template Repository](https://github.com/CDCgov/template) for more information about [contributing to this repository](https://github.com/CDCgov/template/blob/main/CONTRIBUTING.md), [public domain notices and disclaimers](https://github.com/CDCgov/template/blob/main/DISCLAIMER.md), and [code of conduct](https://github.com/CDCgov/template/blob/main/code-of-conduct.md).
