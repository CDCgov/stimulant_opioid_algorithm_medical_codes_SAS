
*###############################################################################################################
# Code Overview (this information can also be found in the accompanying ReadMe)

# Author: Minchan (Daisy) Shi
# Date: September 1, 2024

## Purpose

# The ‘create_output_table’ macro is the key component of this algorithm. It generates an output table of medical
# records identified for having stimulant or opioid use involvement based on mapping rules defined in an external
# Excel file ("Code_Mapping_GitHub.xlsx") called in the macro. The Excel file maps medical codes to different types
# of stimulant use or opioid use. The macro applies the mapping rules in the Excel file to categorize and filter
# input data (coded medical data) for patterns of non-therapeutic stimulant use, opioid use, and other related health
# outcomes. It also derives a variable for co-use based on the detection of both opioid and stimulant use in the same
# medical record. The macro handles various types of input data (CSV, Excel, SAS, database, or preloaded data, and
# takes several parameters as arguments. The parameters are outlined below and in the accompanying ReadMe file.  

## Macro Parameters

### code_mapping_file
# **Description:**Path to the code mapping Excel file `Code_Mapping_GitHub.xlsx,` which contains medical codes mapped 
    to output variables, and is provided in this repository.  To run the ‘create_output_table’ macro, specify the 
    location (path) where you saved the file under 'code_mapping_file parameter'. 
# **Example:** "path/to/Code_Mapping_GitHub.xlsx"

### code_system_name
  **Description:** Name of the medical code system to subset the code mapping file by. Users can choose from 
    "ICD-10-CM", "HCPCS", "RXNORM", "SNOMED", "LOINC", or NULL (not specifying any code system).
  **Examples:** "ICD-10-CM" "HCPCS" or NULL

### dataType
# **Description:** Type of input data containing medical data to be searched. Supported types include
#   "csv", "xlsx", "sas", or "preloaded_data".
# **Examples:** dataType = csv, xlsx, sas, or preloaded_data (only one format is allowed)

### inputPath
# **Description:** The path to the folder where the input file, which contains the coded medical data to be searched,
#   is located. Enter NULL if the datatype is "preloaded_data".
# **Example:** C:\Users\sse6\Desktop\Github, NULL.

### inputFileName
# **Description:** Name of the input file. 
# **Example:** fake_data,  

### columns_to_keep
# **Description:** Columns (variables) from the input data to include in the output table.
# **Examples:** ID VisitType

### output_table_name  
# **Description:** Name of the output file. The output is only available in SAS format. 
# **Examples:** results_file

### code
# **Description:** Name of the column containing codes to match against mappings.(only allow one variable)
# **Example:** Code(the corresponding variable in the provided sample input data (fake_data))

### codesys_name  (optional)
# **Description:** The column name (variable) in your input data set, containing the names of the medical 
#   code system types for the medical codes in variable containing medical codes (parameter ‘code’).
#   Allows user to subset the input data by a specific medical code system type. Enter NULL if you do not
#   want to filter rows of the input data based on the specified condition, or if the parameter 
#   ‘code_system_name’ is not set to NULL. 
# **Examples:** codesys_name = CodeType (CodeType is a variable name in your input data).

### searching_text (optional)
# **Description: Description: Subsets the input data based on a specified medical code type. These are the
#   values in the column name (variable) specified in the 'codesys_name' parameter above. If 'codesys_name'
#   is NULL, then 'searching_text' should also be NULL. Enter NULL if you do not want to filter rows of the
#   input data based on a medical code system, or if the parameter ‘code_system_name’ is NOT set to NULL.
# **Example:**searching_text = ICD-10-CM

###############################################################################################################;

*######################################################################################
# The following code creates the macro called  `create_output_table`.                 #
# This code is fixed and should not be modified. You can run it as is in this section.#
#######################################################################################;

%macro create_output_table(
	code_mapping_file=, 
	code_system_name=, 
	dataType=, inputPath=,
	inputFileName=, 
	columns_to_keep=, 
	output_table_name=, 
	code=, codesys_name=, 
	searching_text=
);
	   	
*Imports the provided excel file that maps medical codes to outcome variables;
proc import 
    datafile= "&code_mapping_file"
	out = code
    dbms=xlsx
    replace;
    getnames=yes;
    sheet="Code_Mapping";
    range="A:AB";
run;

data code;
    set code;
    %if %length(&code_system_name) > 0 and %upcase(&code_system_name) ne NULL
		%then %do;
        	if CODE_SYSTEM in (&code_system_name);
    %end;
    %else %do;
        /* Includes all records if &code_system_name is NULL or not provided */
        if CODE_SYSTEM ne "";
    %end;
run;


%macro OPIOID_RXNORM(macro_variable, variable_name);
    options notes; /* Ensures notes are visible in the log */

    /* Clears the macro variable if it exists */
    %if %symexist(&macro_variable) %then %do;
        %SYMDEL &macro_variable;
    %end;

    %global &macro_variable;

    %put NOTE: Executing PROC SQL with OUTOBS=1500;

    proc sql noprint outobs=1500;
        select compress(quote(CODE),' ') into :&macro_variable separated by ', '
        from code
        where &variable_name = 1;
    quit;

    %put NOTE: PROC SQL completed.;

    %let len = %sysfunc(countw(%superq(&macro_variable), %str(,)));
    %if &len = 0 %then %do;
        %let &macro_variable = ' ';
    %end;

    %put NOTE: The "OUTOBS=1500" option is set to limit the number of observations processed.
               This is done to manage memory usage during the SAS session.;
  
%mend;

/* Execute the OPIOID_RXNORM macro */
%OPIOID_RXNORM(OPIOID_ANY_CODE_RXNORM1, OPIOID_ANY_CODE);


%macro OPIOID_RXNORM1(macro_variable,variable_name);
options notes;
    /* Clear the macro variable if it exists */
    %if %symexist(&macro_variable) %then %do;
        %SYMDEL &macro_variable;
    %end;

%global &macro_variable ; 
proc sql noprint ;
  select compress(quote(CODE),' ') into :&macro_variable separated by ', '  
  from code
  where &variable_name = 1  and CODE NOT IN (&OPIOID_ANY_CODE_RXNORM1) ;
quit;

%let len = %sysfunc(countw(%superq(&macro_variable), %str(,)));
/*%put &macro_variable Total code number is &len;
/* %put;*/
%if &len =0 %then %do;
%let &macro_variable = ' ';
%end;

%mend;

%OPIOID_RXNORM1(OPIOID_ANY_CODE_RXNORM2,OPIOID_ANY_CODE)


%macro sql_store_ICD(macro_variable,variable_name);
options notes;
    /* Clear the macro variable if it exists */
    %if %symexist(&macro_variable) %then %do;
        %SYMDEL &macro_variable;
    %end;


%global &macro_variable;

proc sql noprint;
  select compress(quote(CODE),' ')  into : &macro_variable separated by ',' 
  from code
  where &variable_name = 1 
  order by CODE desc;
quit;
/* Count the elements in &&&macro_variable */
%let len = %sysfunc(countw(%superq(&macro_variable), %str(,)));
/* %put &macro_variable Total code number is &len;
/* %put &&&macro_variable; /* list out each of the code in code mapping file*/
%if &len =0 %then %do;
%let &macro_variable = ' ';
%end;
%mend;

%sql_store_ICD(STIM_ANY_CODE,STIM_ANY_CODE)
%sql_store_ICD(DRUGSCREEN_CODE,DRUGSCREEN_CODE)
%sql_store_ICD(STIM_NON_TX_UNSP_CODE,STIM_NON_TX_UNSP_CODE)
%sql_store_ICD(STIM_TX_CODE,STIM_TX_CODE)
%sql_store_ICD(TX_METHYLPHENIDATE_CODE,TX_METHYLPHENIDATE_CODE)
%sql_store_ICD(TX_DEXTROAMPHETAMINE_CODE,TX_DEXTROAMPHETAMINE_CODE)
%sql_store_ICD(TX_AMPHETAMINE_CODE,TX_AMPHETAMINE_CODE)
%sql_store_ICD(TX_DEXMETHYLPHENIDATE_CODE,TX_DEXMETHYLPHENIDATE_CODE)
%sql_store_ICD(TX_LISDEXAMFETAMINE_CODE,TX_LISDEXAMFETAMINE_CODE)
%sql_store_ICD(TX_AMPHET_DEXTROAMPHET_CODE,TX_AMPHET_DEXTROAMPHET_CODE)
%sql_store_ICD(STIM_MISUSE_CODE,STIM_MISUSE_CODE)
%sql_store_ICD(MISUSE_METHYLPHENIDATE_CODE,MISUSE_METHYLPHENIDATE_CODE)
%sql_store_ICD(MISUSE_AMPHETAMINE_CODE,MISUSE_AMPHETAMINE_CODE)
%sql_store_ICD(STIM_ILLICIT_CODE,STIM_ILLICIT_CODE)
%sql_store_ICD(ILLICIT_COCAINE_CODE,ILLICIT_COCAINE_CODE)
%sql_store_ICD(ILLICIT_METHAMPHETAMINE_CODE,ILLICIT_METHAMPHETAMINE_CODE)
%sql_store_ICD(ILLICIT_MDMA_CODE,ILLICIT_MDMA_CODE)
%sql_store_ICD(OPIOID_MISUSE_CODE,OPIOID_MISUSE_CODE)
%sql_store_ICD(OPIOID_ILLICIT_CODE,OPIOID_ILLICIT_CODE)
%sql_store_ICD(OPIOID_NON_TX_UNSP_CODE,OPIOID_NON_TX_UNSP_CODE)

%let var = STIM_ANY_CODE DRUGSCREEN_CODE STIM_TX_CODE STIM_NON_TX_UNSP_CODE
TX_METHYLPHENIDATE_CODE TX_DEXTROAMPHETAMINE_CODE TX_AMPHETAMINE_CODE 
TX_DEXMETHYLPHENIDATE_CODE TX_LISDEXAMFETAMINE_CODE TX_AMPHET_DEXTROAMPHET_CODE
STIM_MISUSE_CODE MISUSE_METHYLPHENIDATE_CODE MISUSE_AMPHETAMINE_CODE STIM_ILLICIT_CODE
ILLICIT_COCAINE_CODE ILLICIT_METHAMPHETAMINE_CODE ILLICIT_MDMA_CODE OPIOID_ANY_CODE
OPIOID_MISUSE_CODE OPIOID_ILLICIT_CODE OPIOID_NON_TX_UNSP_CODE STIM_ANY_NON_TX_CODE
OPIOID_ANY_NON_TX_CODE;

%if %upcase(&dataType) eq PRELOADED_DATA %then %do;
data output(compress=yes);
  set &inputFileName;
  where not missing(&code);
%end;

%else %if %upcase(&dataType) eq SAS %then %do;
libname out "&inputPath.";
	data output;
	set out.&inputFileName;
	run;
%end;

%else %if %upcase(&dataType) eq EXCEL %then %do;
	proc import datafile= "&inputPath.\&inputFileName..xlsx";
		out=output
		dbms=xlsx replace;
	run;
%end;

%else %if %upcase(&dataType) eq CSV %then %do;
	proc import datafile="&inputPath.\&inputFileName..csv"
		out=output
		dbms=csv
		replace;
	run;
%end;

%else %do;
    %put ERROR: Invalid data type specified. choose from (PRELOADED_DATA,SAS,EXCEL or CSV);
%end;

data output1(compress=yes);
 set output;
	array char[*] &columns_to_keep;	
	do i = 1 to dim(char);
		char[i] = put(char[i], $char.);
	end;

    &code = strip(put(&code,100.));
	&code = compress(&code, '.');

 %if &codesys_name = NULL and &searching_text = NULL %then %do;
	
	if &code in (&OPIOID_ANY_CODE_RXNORM1) or &code in (&OPIOID_ANY_CODE_RXNORM2)
		THEN OPIOID_ANY_CODE = 1; 
			else OPIOID_ANY_CODE = 0;
	if &code in (&STIM_ANY_CODE) 
		THEN STIM_ANY_CODE = 1; 
			else STIM_ANY_CODE = 0;
	if &code in (&DRUGSCREEN_CODE) 
		THEN DRUGSCREEN_CODE = 1; 
			else DRUGSCREEN_CODE = 0;
	if &code in (&STIM_TX_CODE) 
		THEN STIM_TX_CODE = 1; 
			else STIM_TX_CODE = 0;
	if &code in (&STIM_NON_TX_UNSP_CODE)
		THEN STIM_NON_TX_UNSP_CODE = 1; 
			else STIM_NON_TX_UNSP_CODE = 0;
	if &code in (&TX_METHYLPHENIDATE_CODE) 
		THEN TX_METHYLPHENIDATE_CODE = 1; 
			else TX_METHYLPHENIDATE_CODE = 0;
	if &code in (&TX_DEXTROAMPHETAMINE_CODE) 
		THEN TX_DEXTROAMPHETAMINE_CODE = 1; 
			else TX_DEXTROAMPHETAMINE_CODE = 0;
	if &code in (&TX_AMPHETAMINE_CODE) 
		THEN TX_AMPHETAMINE_CODE = 1; 
			else TX_AMPHETAMINE_CODE = 0;
	if &code in (&TX_DEXMETHYLPHENIDATE_CODE) 
		THEN TX_DEXMETHYLPHENIDATE_CODE = 1; 
			else TX_DEXMETHYLPHENIDATE_CODE = 0;
	if &code in (&TX_LISDEXAMFETAMINE_CODE) 
		THEN TX_LISDEXAMFETAMINE_CODE = 1; 
			else TX_LISDEXAMFETAMINE_CODE = 0;
	if &code in (&TX_AMPHET_DEXTROAMPHET_CODE) 
		THEN TX_AMPHET_DEXTROAMPHET_CODE = 1; 
			else TX_AMPHET_DEXTROAMPHET_CODE = 0;
	if &code in (&STIM_MISUSE_CODE) 
		THEN STIM_MISUSE_CODE = 1; 
			else STIM_MISUSE_CODE = 0;
	if &code in (&MISUSE_METHYLPHENIDATE_CODE) 
		THEN MISUSE_METHYLPHENIDATE_CODE = 1; 
			else MISUSE_METHYLPHENIDATE_CODE = 0;
	if &code in (&MISUSE_AMPHETAMINE_CODE)
		THEN MISUSE_AMPHETAMINE_CODE = 1; 
			else MISUSE_AMPHETAMINE_CODE = 0;
	if &code in (&STIM_ILLICIT_CODE) 
		THEN STIM_ILLICIT_CODE = 1; 
			else STIM_ILLICIT_CODE = 0;
	if &code in (&ILLICIT_COCAINE_CODE) 
		THEN ILLICIT_COCAINE_CODE = 1; 
			else ILLICIT_COCAINE_CODE = 0;
	if &code in (&ILLICIT_METHAMPHETAMINE_CODE) 
		THEN ILLICIT_METHAMPHETAMINE_CODE = 1; 
			else ILLICIT_METHAMPHETAMINE_CODE = 0;
	if &code in (&ILLICIT_MDMA_CODE) 
		THEN ILLICIT_MDMA_CODE = 1; 
			else ILLICIT_MDMA_CODE = 0;
	if &code in (&OPIOID_MISUSE_CODE)
		THEN OPIOID_MISUSE_CODE = 1; 
			else OPIOID_MISUSE_CODE = 0;
	if &code in (&OPIOID_ILLICIT_CODE) 
		THEN OPIOID_ILLICIT_CODE = 1; 
			else OPIOID_ILLICIT_CODE = 0;
	if &code in (&OPIOID_NON_TX_UNSP_CODE) 
		THEN OPIOID_NON_TX_UNSP_CODE = 1; 
			else OPIOID_NON_TX_UNSP_CODE = 0;

%end;
%else %do;
 	if (&code in (&OPIOID_ANY_CODE_RXNORM1) AND &codesys_name = &searching_text) 
		or (&code in (&OPIOID_ANY_CODE_RXNORM2) AND &codesys_name =&searching_text) 
		THEN  OPIOID_ANY_CODE=1 ; 
			else OPIOID_ANY_CODE=0 ; 
	if &code  in (&STIM_ANY_CODE) AND &codesys_name = &searching_text  
		THEN  STIM_ANY_CODE=1; 	
 			else STIM_ANY_CODE=0 ;
	if &code  in (&DRUGSCREEN_CODE) AND &codesys_name =&searching_text
		THEN  DRUGSCREEN_CODE=1 ; 
			else DRUGSCREEN_CODE=0 ;
	if &code  in (&STIM_TX_CODE) AND &codesys_name =&searching_text
		THEN  STIM_TX_CODE=1 ;
			else STIM_TX_CODE=0 ;
	if &code  in (&STIM_NON_TX_UNSP_CODE) AND &codesys_name =&searching_text
		THEN  STIM_NON_TX_UNSP_CODE=1 ; 
			else STIM_NON_TX_UNSP_CODE=0 ;
	if &code  in (&TX_METHYLPHENIDATE_CODE) AND &codesys_name = &searching_text
		THEN  TX_METHYLPHENIDATE_CODE=1 ; 
			else TX_METHYLPHENIDATE_CODE=0 ;
	if &code  in (&TX_DEXTROAMPHETAMINE_CODE) AND &codesys_name =&searching_text
		THEN  TX_DEXTROAMPHETAMINE_CODE=1 ; 
			else TX_DEXTROAMPHETAMINE_CODE=0 ;
	if &code  in (&TX_AMPHETAMINE_CODE) AND &codesys_name =&searching_text
		THEN  TX_AMPHETAMINE_CODE=1; 
			else TX_AMPHETAMINE_CODE=0 ;
	if &code  in (&TX_DEXMETHYLPHENIDATE_CODE) AND &codesys_name = &searching_text
		THEN  TX_DEXMETHYLPHENIDATE_CODE=1 ;
			else TX_DEXMETHYLPHENIDATE_CODE=0 ;
	if &code  in (&TX_LISDEXAMFETAMINE_CODE) AND &codesys_name =&searching_text
		THEN  TX_LISDEXAMFETAMINE_CODE=1 ; 
			else TX_LISDEXAMFETAMINE_CODE=0 ;
	if &code  in (&TX_AMPHET_DEXTROAMPHET_CODE) AND &codesys_name = &searching_text
		THEN  TX_AMPHET_DEXTROAMPHET_CODE=1 ; 
			else TX_AMPHET_DEXTROAMPHET_CODE=0 ;
	if &code  in (&STIM_MISUSE_CODE) AND &codesys_name =&searching_text 
		THEN  STIM_MISUSE_CODE=1 ;
			else STIM_MISUSE_CODE=0 ;
	if &code  in (&MISUSE_METHYLPHENIDATE_CODE) AND &codesys_name =&searching_text
		THEN  MISUSE_METHYLPHENIDATE_CODE=1 ; 
			else MISUSE_METHYLPHENIDATE_CODE=0 ;
	if &code  in (&MISUSE_AMPHETAMINE_CODE) AND &codesys_name =&searching_text
		THEN  MISUSE_AMPHETAMINE_CODE=1 ; 
			else MISUSE_AMPHETAMINE_CODE=0 ;
	if &code  in (&STIM_ILLICIT_CODE) AND &codesys_name =&searching_text  
		THEN  STIM_ILLICIT_CODE=1 ; 
			else STIM_ILLICIT_CODE=0 ;
	if &code  in (&ILLICIT_COCAINE_CODE) AND &codesys_name = &searching_text
		THEN  ILLICIT_COCAINE_CODE=1 ; 
			else ILLICIT_COCAINE_CODE=0 ;
	if &code  in (&ILLICIT_METHAMPHETAMINE_CODE) AND &codesys_name =&searching_text
		THEN  ILLICIT_METHAMPHETAMINE_CODE=1 ; 
			else ILLICIT_METHAMPHETAMINE_CODE=0 ;
	if &code  in (&ILLICIT_MDMA_CODE) AND &codesys_name =&searching_text  
		THEN  ILLICIT_MDMA_CODE=1 ; 
			else ILLICIT_MDMA_CODE=0 ;
	if &code  in (&OPIOID_MISUSE_CODE) AND &codesys_name =&searching_text 
		THEN  OPIOID_MISUSE_CODE=1 ; 
			else OPIOID_MISUSE_CODE=0 ;
	if &code  in (&OPIOID_ILLICIT_CODE) AND &codesys_name =&searching_text
		THEN  OPIOID_ILLICIT_CODE=1 ; 
			else OPIOID_ILLICIT_CODE=0 ;
	if &code  in (&OPIOID_NON_TX_UNSP_CODE) AND &codesys_name = &searching_text
		THEN  OPIOID_NON_TX_UNSP_CODE=1 ; 
			else OPIOID_NON_TX_UNSP_CODE=0 ;
%end;

/* STIM_ANY_NON_TX_CODE logic */
    if STIM_NON_TX_UNSP_CODE = 1 or STIM_MISUSE_CODE = 1 or STIM_ILLICIT_CODE = 1 then do;
        STIM_ANY_NON_TX_CODE = 1;
    end;
    else do;
        STIM_ANY_NON_TX_CODE = 0;
    end;

 /* OPIOID_ANY_NON_TX_CODE logic */
    if OPIOID_NON_TX_UNSP_CODE = 1 or OPIOID_MISUSE_CODE = 1 or OPIOID_ILLICIT_CODE = 1 then do;
        OPIOID_ANY_NON_TX_CODE = 1;
    end;
    else do;
        OPIOID_ANY_NON_TX_CODE = 0;
    end;

/* exclude encounter_id when all of the ouput variables "&var(output variables)" are 0; i.e. if nothing found 
  across all of the &var(output variables), then we do not need to keep them in the file. */
array var_array[*] &var;

flag = 0;

do i = 1 to dim(var_array);
	if var_array[i] ne 0 then do;
		flag = 1;
		leave;
	end;
end;

if flag = 1;

KEEP &columns_to_keep  &var;

/*This code will generate a summary table of each unique ID and only keep the max value,i.e. either 1 or 0 
of the output variables flagged*/
proc summary data = output1 nway;
  class &columns_to_keep;
  var &var;
  output out = &output_table_name(drop=_:) max=;
run;

/*This code derives a variable for co-use of stimulants and opioids based on the output table*/
data final_table; 
	length STIM_OPIOID_COUSE 8.; /*Initiating the stimulant, opioid co-use variable*/
	set &output_table_name; 
	if OPIOID_ANY_NON_TX_CODE = 1 and STIM_ANY_NON_TX_CODE =1 
		then STIM_OPIOID_COUSE = 1; 
			else STIM_OPIOID_COUSE =0; 
run; 

%put NOTE: The algorithm has been successfully executed and completed. Please review the output for further details.;
%mend;


*###############################################################################################
# The next blocks of code provide examples of excuting the 'create_output_table' macro          #
# using a variety of settings for the parameters. Using your input datafile and the             #
# provided code mapping file, you can enter your specific parameters to the macro and execute   #
# it to generate the final output table. Example 1 provides detailed explanatations for each    #
# parameter.                                                                                    #
#################################################################################################;

*Example 1: Using an external SAS input file, and using specified code_systems;	
%create_output_table(
	/*Path to the code mapping excel file provided to you*/
	code_mapping_file = C:\Users\username\Downloads\stimulant_opioid_algorithm_medical_codes_SAS-main\stimulant_opioid_algorithm_medical_codes_SAS-main\Code_Mapping_GitHub.xlsx,
	
	/*Type of file for your input data (medical record data to be searched).*/ 
	dataType= SAS, /*Supported types include : "csv", "xlsx", "sas", or "preloaded_data". */
	
	/*Path to the location of the input file.  Provide `NULL` if the dataType is "preloaded_data". */
	inputPath= C:\Users\username\Downloads\stimulant_opioid_algorithm_medical_codes_SAS-main\stimulant_opioid_algorithm_medical_codes_SAS-main, 
	
	/*Name of the input file */
	inputFileName = fake_data,
	
	/*Name of the columns (variables) in the input file (fake data in this example) that you want to include
	in the output table. You can add more variable names based on your need. Use a blank space as the delimiter.
	DO NOT use commas*/
	columns_to_keep = ID VisitType,
	
	/*Name of the output file. The output is only available in SAS format. After running the macro, you can add
	your own code, using built in SAS output delivery system (ODS) functions to export the SAS file in another
	format */
	output_table_name = example1_results_file,
	
	/*Enter the name of the column(variable) containing medical codes in the input data (coded medical record data). 
	This allows to match against mappings. If the input data does not have a single column(variable) for the medical 
	codes, you will have to create this in your input file before running the macro. Only one variable should be listed*/
	code = Code,

	/*This parameter allows you to apply the provided code mapping excel file to your input file based on one or more
	 medical code systems of interest. Enter the name of the code system you intend use. This should match the code 
	 system name(s)in the code mapping excel file provided. You can choose from "ICD-10-CM", "HCPCS", "RXNORM", "SNOMED",
	 "LOINC". Enter NULL if you don't want to specify a code system*/
	code_system_name = NULL,/*if including a system, use quotations*/

	/*NOTE: The following two parameters ('codesys_name' and 'search_text') work together to subset your input data
	 by a particular medical code system (ex. "ICD-10-CM", "HCPCS", "SNOMED"...). They are optional and should both have
	 a value of NULL if you choose not to use them. They should ONLY be specified IF the parameter 'code_system_name'=NULL.
	 
	/*Optional: to subset your input data. Enter the column name(variable) in your input data set, containing the names
	 of the type of medical code you are interested in. This allows you to subset your input data based on a specific
	 type of code. Enter NULL if you do not want to subset your input data in this way */
	codesys_name = CodeType,
	
	/*Optional: Enter the text name of the medical code type you are interested in. These are the values in the column name
	 (variable) specified for the 'codesys_name' parameter above. If 'codesys_name' is NULL, then 'searching_text' should 
	 also be NULL. If you entered a value other than "NULL" for the 'code_system_name' parameter, enter "NULL".*/
	searching_text = "ICD-10-CM"); /*enter in quotes, enter NULL without quotes*/ 



*Example 2: Using an external CSV input file, and specifying a code_system_name to use in the mapping file;
%create_output_table(	
	code_mapping_file = C:\Users\username\Downloads\stimulant_opioid_algorithm_medical_codes_SAS-main\stimulant_opioid_algorithm_medical_codes_SAS-main\Code_Mapping_GitHub.xlsx,
	code_system_name ="ICD-10-CM",
	dataType= CSV,
	inputPath= C:\Users\username\Downloads\stimulant_opioid_algorithm_medical_codes_SAS-main\stimulant_opioid_algorithm_medical_codes_SAS-main, 
	inputFileName = fake_data,
	columns_to_keep = ID VisitType CodeType ,
	output_table_name = example2_results_file,
	code = Code,
	codesys_name = NULL ,
	searching_text =  NULL
	);

*Example 3: Using preloaded_data input file;

/*Step 1: Create the input file in SAS using a data step*/                                                                                 
data fake_data1;
	length ID $8. VisitType $10. Code $20. CodeType $20.; /*Must specify  variable lengths*/
	input ID $ VisitType $ Code $ CodeType $20.;
	datalines;
		123X ED C9046 HCPCS
		456X ED-to-IP T40694 ICD-10-CM
		789Y IP F33.9 ICD-10-CM
		012Y IP F1111 ICD-10-CM
		254P ED-to-IP F12222 ICD-10-CM
		835T ED F15220 ICD-10-CM
		624X IP F18120 ICD-10-CM
		826P NA G9578 HCPCS
		426P OP Z915 ICD-10-CM
		264X IP F419 ICD-10-CM
		926P ED F419 ICD-10-CM
		012Y IP F1123 ICD-10-CM
		913Z OP 372862 RXNORM
		837w ED 151612 RXNORM
		787x ED 699449003 SNOMED
	;
run;

/*Step 2: Fill in the parameters in the 'create_output_table' macro. Since the dataset was created in SAS,
 use "preloaded_data" for the data_type parameter. Execute the macro after filling in the parameters*/
%create_output_table(	
	code_mapping_file = C:\Users\username\Downloads\stimulant_opioid_algorithm_medical_codes_SAS-main\stimulant_opioid_algorithm_medical_codes_SAS-main\Code_Mapping_GitHub.xlsx,
	code_system_name = NULL,
	dataType= preloaded_data,
	inputPath= NULL , /*Enter NULL when using preloaded data*/
	inputFileName= fake_data1,
	columns_to_keep = ID VisitType ,
	output_table_name = example3_results_file,
	code = Code,
	codesys_name =  NULL,
	searching_text =  NULL 
	);


