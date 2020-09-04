
*! version 1.2.1 - 6feb2020
*! authors: Federico Belotti, Domenico Depalo

program define screening, rclass
version 8.0
syntax [if] [in], SOURCEs(passthru) KEYs(passthru) [ Letters(numlist >0 integer) Explore(string) CASES(string) 				///
				                     NOWARNings NEWcode(string) RECode(string asis) CHECKsources TABCHECK SAVE MEMcheck TIME ]

*local vv : di "version " string(max(8,c(stata_version))) ":"
loc vv "`c(stata_version)'"

*** FROM HERE: FOR OLD ADO COMPARISON
if "`time'"!="" {
	timer clear
	mata: timer_clear()
	timer on 1
}

****************************************************************
*** PARSING OF OPTION SOURCES (needed because of the rules)  ***
****************************************************************

*** Check the spell of suboptions
if "`explore'" != "" {
	local suboption_explore "tab count"
	local check_opt_explore " `explore' "
	local ncheck_opt_explore: word count `check_opt_explore'
	local spellcheck "0"
	foreach sub of local suboption_explore {
		if regexm("`check_opt_explore'", "[ ]`sub'[ ]")==1  local spellcheck = `spellcheck' + 1
	}
	if `spellcheck'< `ncheck_opt_explore'{
		noi di in red as error "-explore()- sub-options are misspecified."
		error 198
		exit
	}
}

gettoken newcode opt_newcode: newcode, parse(",")
local opt_newcode = rtrim(ltrim(regexr("`opt_newcode'", ",", "")))
local suboption_newcode "add replace label numeric"

*** Check the spell of suboptions
if "`opt_newcode'" != "" {
	local check_opt_newcode " `opt_newcode' "
	local ncheck_opt_newcode: word count `check_opt_newcode'
	local spellcheck "0"
	foreach sub of local suboption_newcode {
		if regexm("`check_opt_newcode'", "[ ]`sub'[ ]")==1  local spellcheck = `spellcheck' + 1
	}
	if `spellcheck'< `ncheck_opt_newcode'{
		noi di in red as error "-newcode()- sub-options are misspecified."
		error 198
		exit
	}
}

local count = 1
foreach sub of local suboption_newcode {
	local opt_newcode`count' = regexm("`opt_newcode'", "`sub'")
	local count = `count'+1
}
*** -Newcode- suboptions
** 1 add
** 2 replace
** 3 label
** 4 numeric

gettoken sources opt_sources: sources, parse(",")
local sources=rtrim(ltrim(regexr("`sources'", "sources", "")))
local sources=rtrim(ltrim(regexr("`sources'", "\(", "")))
local sources=rtrim(ltrim(regexr("`sources'", "\)", "")))

if "`opt_sources'"!=""  {
	local opt_sources=rtrim(ltrim(regexr("`opt_sources'", ",", "")))
	local opt_sources=regexr("`opt_sources'", "\)", "")
}
local suboption_sources "lower upper trim itrim removeblank removesign"

*** Check the spell of suboptions
if "`opt_sources'" != "" {
	local check_opt_sources " `opt_sources' "
	local ncheck_opt_sources: word count `check_opt_sources'
	local spellcheck "0"
	foreach sub of local suboption_sources {
		if regexm("`check_opt_sources'", "[ ]`sub'[ ]")==1  local spellcheck = `spellcheck' + 1
	}
	if `spellcheck'< `ncheck_opt_sources'{
		noi di in red as error "-sources()- sub-options are misspecified."
		error 198
		exit
	}
}

local count = 1
foreach sub of local suboption_sources {
	local opt_sources`count' = regexm("`opt_sources'", "`sub'")
	local count = `count'+1
}

*** Suboptions
** 1 lower
** 2 upper
** 3 trim
** 4 itrim
** 5 removeblank
** 6 removesign

local nsources: word count `sources'

****************************************************************
********* CHECK THE ADMISSIBLE MULTIPLE SUBOPTION **************
*********** FOR OPTION SOURCES AND CHECK THE *******************
**************** EXISTENCE OF VARIABLE NEWCODE *****************
****************************************************************

if "`opt_sources'"!=""  {

	if (`opt_sources1'==1 & `opt_sources2'==1) {
		noi di as error "Option -sources-: you cannot specify sub-option -lower- and -upper- simultaneously"
		error 198
		exit
	}
	if (`opt_sources3'==1 & `opt_sources5'==1) {
		noi di as error "Option -sources-: you cannot specify sub-option -trim- and -removeblank- simultaneously"
		error 198
		exit
	}
	if (`opt_sources4'==1 & `opt_sources5'==1) {
		noi di as error "Option -sources-: you cannot specify sub-option -trim- and -removeblank- simultaneously"
		error 198
		exit
	}
}

if "`newcode'"!="" & `opt_newcode2' == 0 {
	**** Check if newcode variable is already IN
	capture confirm new variable `newcode'
	if _rc!=0 {
		noi di in red as error "Variable `newcode' is already defined."
		error 110
	}
}

****************************************************************
********* CHECK THE EXISTENCE OF SOURCE VARIABLES **************
*********** AND IF SOURCE VARIABLES ARE STRING *****************
*********** AND WARNING W.R.T LOWER OR UPPER CASE **************
****************************************************************

local listof_sources_length ""
foreach x of local sources   {

	local lower_upper_`x' (lower(`x'))
	capture assert `lower_upper_`x'' == `x'
	if _rc!=0 {
		local lower_upper_`x' "1"
	}
	else local lower_upper_`x' "0"
	capture confirm variable `x', exact
		if _rc!=0 {
	    	noi di as error "Variable `x' is not in your dataset."
	    	error 111
	    	exit
		}
	capture confirm string variable `x'
		if _rc!=0 {
	    	noi di as error "Source variables" in yellow " must be" as error " string. " in yellow "`x'" as error " is not a string variable."
	    	error 107
	    	exit
		}
	local length_source_`x': type `x'
	local length_source_`x' = substr("`length_source_`x''", 4, .)
	local listof_sources_length "`listof_sources_length' `length_source_`x''"
}

loc check_strL = regexm("`listof_sources_length'", "L")

if "`memcheck'"!= "" & `vv'<12 {
	numlist "`listof_sources_length'", sort
	local max_sources_length = word(r(numlist),-1)
}
local number_of_sources: word count `sources'

****************************************************************
******* CHECK IF OPTIONS ARE CORRECTLY SPECIFIED  **************
****************************************************************

*** Important: Creates a new local or_recode=1 for subsequent use
if `"`recode'"'!="" {
	local or_recode "1"
}
else {
	local or_recode "0"
}

if `opt_newcode3' == 1 & `or_recode'==1 {
	noi di in red as error "-label- suboption cannot be specified if -recode()- is specified."
	error 198
}

if `opt_newcode4' == 1 & `or_recode'==0 {
	noi di in red as error "-numeric- suboption can be specified only if -recode()- option is specified."
	noi di in red as error "The new variable `newcode' is by default a numeric variable"
	error 198
}

if `opt_newcode4' == 1 & `opt_newcode3' {
	noi di in red as error "Suboptions -numeric- and -label- cannot be specified simultaneously."
	error 198
}

if `or_recode'==1 & "`newcode'"=="" {
	noi di in red as error "-recode()- option must be specified together with -newcode()- option."
	error 198
	exit
}

if "`tabcheck'"!="" & "`checksources'"=="" {
	noi di as error "-tabcheck- option must be specified together with -checksources- option."
	error 198
	exit
}

**** Marksample
marksample touse, strok

**** Obs number
qui count
local all_obs = r(N)

*******************************************************************
*** PARSING OF OPTION RECODE (due to recoding rules and regexs) ***
*******************************************************************

** Important: initialize local -nsregexs_yes-
local nsregexs_yes "0"

if `or_recode'==1 {

	local error_recode `"`recode'"'
	local error_recode: subinstr local error_recode " ," ",", all
	local error_recode: subinstr local error_recode ", " ",", all
	local error_recode: subinstr local error_recode `"""' `" " "',all
	local nerror_recode: word count `error_recode'

	*** Checks if the user correctly specifies the recode() argument
	if mod(`nerror_recode',2) == 1 {
		noi di as error "The argument of option -recode()- must contain an even number of elements."
		noi di as error "Each user-defined code must be specified with its own recoding rule."
		error 198
		exit
	}

	*** Compute numbers for option recode arguments
	local nr = `nerror_recode'/2

	*** Initialize rules
	forvalues i = 1/`nr' {
		local user_rule_`i' ""
	}
	local nr_counter = 1
	*** Checks the compulsory presence of double quotes for user-defined codes
	forvalues i = 1/`nerror_recode' {
		gettoken user_rule_component`i' error_recode: error_recode, qed(check_quotes)
			if mod(`i',2) != 1 {
				if `check_quotes'!=1  {
					noi di as error "-recode()- option: user-defined codes must be specified within double quotes."
					error 198
					exit
				}
			}
			local user_rule_`nr_counter' "`user_rule_`nr_counter'' `user_rule_component`i''"
			if mod(`i',2) != 1 {
				local nr_counter=`nr_counter'+1
			}
	}

	*** Fix rules specified by the user
	local user_rules ""
		forvalues ur=1/`nr' {
			gettoken upd_user_rules user_rule_`ur': user_rule_`ur'
			local check_upd_user_rules = subinstr("`upd_user_rules'", ",", " ",.)
				foreach cont of local check_upd_user_rules {
					capture confirm integer number `cont'
					if _rc!=0 {
		    			noi di as error "Recoding rule " in yellow "`upd_user_rules'" as error " must be an integer number."
		    			error 198
		    			exit
					}
				}
			local user_rules "`user_rules' `upd_user_rules'"
			local user_rule_`ur' = trim("`user_rule_`ur''")
		}

		if regexm(`"`recode'"', "regexs")==1  {
			if regexm("`user_rules'", ",")==1 {
				noi di as error "If -regexs()- or -ustrregexs()- functions are specified as a user-defined code, recoding rules must refer only to one keyword."
    			error 198
    			exit
			}
		}

		*** Fix rules in the case of regexs() function (prefix and postfix. see mata functions)
		local nsregexs ""
		forvalues localnr = 1 / `nr' {
			local nsregexs_yes_`localnr' "0"
			forvalues indexofregexs = 0/5 {
				if regexm("`user_rule_`localnr''", "^regexs\(`indexofregexs'\)")==1  {
					local sregexs_`localnr' = `indexofregexs'
					local nsregexs_yes_`localnr' "1"
					local postfix_sregexs_`localnr' = subinstr("`user_rule_`localnr''", ustrregexs(0),"",1)
					if "`postfix_sregexs_`localnr''"!="" {
						CLeanSegni, toc(`postfix_sregexs_`localnr'')
						local postfix_sregexs_`localnr' "$ClEaNsEgNi_____"
						macro drop ClEaNsEgNi_____
					}
				}
				else if regexm("`user_rule_`localnr''", "regexs\(`indexofregexs'\)$")==1  {
					local sregexs_`localnr' = `indexofregexs'
					local nsregexs_yes_`localnr' "1"
					local prefix_sregexs_`localnr' = subinstr("`user_rule_`localnr''", ustrregexs(0),"",1)
					if "`prefix_sregexs_`localnr''"!="" {
						CLeanSegni, toc(`prefix_sregexs_`localnr'')
						local prefix_sregexs_`localnr' "$ClEaNsEgNi_____"
						macro drop ClEaNsEgNi_____
					}
				}
				else if regexm("`user_rule_`localnr''", "regexs\(`indexofregexs'\)")==1  {
					local sregexs_`localnr' = `indexofregexs'
					local nsregexs_yes_`localnr' "1"
					local fix_sregexs_`localnr' = subinstr("`user_rule_`localnr''", ustrregexs(0)," ",.)
					gettoken prefix_sregexs_`localnr' postfix_sregexs_`localnr': fix_sregexs_`localnr'
					if "`prefix_sregexs_`localnr''"!="" {
						CLeanSegni, toc(`prefix_sregexs_`localnr'')
						local prefix_sregexs_`localnr' "$ClEaNsEgNi_____"
						macro drop ClEaNsEgNi_____
					}
					if "`postfix_sregexs_`localnr''"!="" {
						CLeanSegni, toc(`postfix_sregexs_`localnr'')
						local postfix_sregexs_`localnr' "$ClEaNsEgNi_____"
						macro drop ClEaNsEgNi_____
					}
				}
			}
	local nsregexs "`nsregexs' `sregexs_`localnr''"
	}
	local nsregexs_yes: word count `nsregexs'

	if `nsregexs_yes'!=0 {
		if `nsources'>1 {
			noi di as error "-regexs()- or -ustrregexs()- functions are specified as a user-defined code: you can screen only one source variable."
			error 198
			exit
		}
	}

	if `opt_newcode1'==1 & `nsregexs_yes'==0 {
		noi di as error "-add- sub-option can be specified only if -regexs()- or -ustrregexs()- functions are specified as a user-defined code within -recode()- option."
		error 198
		exit
	}

}
else {
	if `opt_newcode1'==1 {
		noi di as error "-add- sub-option can be specified only if -regexs()- or -ustrregexs()- functions are specified as a user-defined code within -recode()- option."
		error 198
		exit
	}
}

****************************************************************
******* FIX KEYS & WARNINGS ABOUT REG EXPR OPERATORS ***********
******* AND MEMORY CHECK IF MEMCHECK IS SPECIFIED **************
****************************************************************

	local regexpr_screen "0"
	local tmp "`keys'FiNeDeLlAsTrInGa"
	local tmp: subinstr local tmp ")FiNeDeLlAsTrInGa" ""
	local tmp: subinstr local tmp "keys(" ""
	local allkey: subinstr local tmp "begin" " ", all
	local allkey: subinstr local allkey "end" " ", all
	local tmp_count: word count `tmp'
	local key_count: word count `allkey'

	if "`memcheck'"!= "" & `vv'<12 {
		local number_of_string_variables "0"
		local number_of_byte_variables "0"
		local row_realmat1 "0"
		local row_realmat2 "0"
		local row_strmat1 "0"
		local row_strmat2 "0"
		local col_realmat1 "0"
		local col_realmat2 "0"
		local col_strmat1 "0"
		local col_strmat2 "0"

		*** Count of required variables & matrices
		  local  row_realmat1 "`all_obs'"
		  local  col_realmat1 = (`number_of_sources' * `key_count')
		if (`opt_sources1'==1 | `opt_sources2'==1)		local  number_of_string_variables = `number_of_string_variables' + 1
		if `opt_sources5'==1		local  number_of_string_variables = `number_of_string_variables' + 1
		if `opt_sources6'==1		local  number_of_string_variables = `number_of_string_variables' + 1
		if `opt_sources3'==1		local  number_of_string_variables = `number_of_string_variables' + 1
		if `opt_sources4'==1		local  number_of_string_variables = `number_of_string_variables' + 1
		if "`checksources'"!=""     local  number_of_byte_variables = `number_of_byte_variables' + (`number_of_sources' * `key_count')
		if "`newcode'"!="" & (`opt_newcode2'==1 | `opt_newcode2'==0) & `or_recode'==0		local  number_of_byte_variables = `number_of_byte_variables' + 1
		if "`newcode'"!="" & (`opt_newcode2'==1 | `opt_newcode2'==0) & `or_recode'==1 	 	local  number_of_string_variables = `number_of_string_variables' + 1
		if `nsregexs_yes'!=0 {
			 local  number_of_string_variables = `number_of_string_variables' + 1
			 local  row_strmat1 "`all_obs'"
			 local  col_strmat1 = (`number_of_sources' * `key_count')
		}
		if "`newcode'"=="" & "`cases'"=="" & `or_recode'==0   local  number_of_byte_variables = `number_of_byte_variables'
		else {
			 local  number_of_byte_variables = `number_of_byte_variables' + `key_count'
			 local  row_realmat2 "`all_obs'"
			 local  col_realmat2 "`key_count'"
		}
		if "`save'"=="" & "`explore'"=="" & `regexpr_screen'==0   local  number_of_string_variables = `number_of_string_variables'
		else {
			  local  number_of_string_variables = `number_of_string_variables' + (`number_of_sources' * `key_count')
			  local  row_strmat2 "`all_obs'"
			  local  col_strmat2 = (`number_of_sources' * `key_count')
		}
		if `opt_newcode2'==1		local  number_of_byte_variables = `number_of_byte_variables' + 1
		if "`cases'"!=""    		local  number_of_byte_variables = `number_of_byte_variables' + `key_count'
		if "`newcode'"!="" & `opt_newcode2'==1 & `or_recode'==1      local  number_of_byte_variables = `number_of_byte_variables' + 1
		if "`save'"!=""      local  number_of_byte_variables = `number_of_byte_variables' + 1

		checkmem, vbyte(`number_of_byte_variables') vstr(`max_sources_length',`number_of_string_variables') mreal1(`row_realmat1',`col_realmat1') mreal2(`row_realmat2',`col_realmat2')  mstr1(`max_sources_length',`row_strmat1',`col_strmat1')  mstr2(`max_sources_length',`row_strmat2',`col_strmat2')

	}
	else di in gr "Memory check is not needed anymore with Stata `vv'"

		local CHeckSegniTot___ "0"
		forvalues i=1/`key_count' {

			local w`i':	word `i' of `allkey'
			CHeckSegni, check(`w`i'') num(`i')
			local CHeckSegni`i'___ "$CHeckSegni___"
			if `CHeckSegni`i'___' != 0  local key`i'_is_a_regexpr "1"
			else   local key`i'_is_a_regexpr "0"
			local CHeckSegniTot___ = `CHeckSegniTot___' + `CHeckSegni`i'___'
			macro drop CHeckSegni___
		}

		if `CHeckSegniTot___' != 0 {
			local regexpr_screen "1"

			if "`nowarnings'"=="" {
				di ""
				di in yellow "WARNING! You are SCREENING some keywords using regular-expression operators like" in green " ^ . ( ) [ ] ? *"
				di in yellow "         Notice that:"
				di in yellow " 1) Option -letter- doesn't work IF a keyword contains regular-expression operators"
				di in yellow " 2) Unless you are looking for a specific regular-expression, regular-expression operators"
				di in yellow "    must be preceded by a backslash " in green "\" in yellow " to ensure keyword-matching (e.g. " in green "\^ \." in yellow " )"
				di in yellow " 3) To match a keyword containing " in green "$" in yellow " or " in green "\" in yellow ", you have to specify them as " in green "[\\$] [\\\]"
			}
		}

	forvalues i=1/`tmp_count' {
		local tmpw`i': word `i' of `tmp'    // create a local for each word in keys
	}


	cap label drop `newcode'_key_label
	forvalues i=1/`key_count' {
		local key`i': word `i' of `allkey'		// create a local for each key in keys

			********************************************************************
			************************* subOPTION LABEL  *************************
			********************************************************************
			if `or_recode'==0 & `opt_newcode3'==1 {
				if `i' == 1 	label define `newcode'_key_label `i' "`key`i''"
				else 			label define `newcode'_key_label `i' "`key`i''", add
			}
	}


	********************************************************************
	*************** Following code return correct keys *****************
	********************************************************************
	forvalues k=1/`key_count' {
		forvalues j=1/`tmp_count' {
			if "`tmpw`j''"=="begin" & "`tmpw`++j''"=="`key`k''"  {
				local key`k'="^`key`k''"
			}
			local j=`--j'+1
		}
	}
	forvalues k=1/`key_count' {
		forvalues j=1/`tmp_count' {
			if "`tmpw`j''"=="end" & "`tmpw`++j''"=="`key`k''"  {
				local key`k'="`key`k''$"
			}
			local j=`--j'+1
		}
	}
	********************************************************************
	****************** Check and Fix for dups ^ and $ ******************
	********************************************************************
	forvalues k=1/`key_count' {
		if regexm("`key`k''", "\^\^") {
			local key`k': subinstr local key`k' "^^" "^"
		}
		if regexm("`key`k''", "\$\$") {
			local key`k': subinstr local key`k' "$$" "$"
		}
	}

	********************************************************************
	**** Following code return correct local key for subsequent use ****
	********************************************************************
	global KeYpAsStHrU_____ ""       // initialization of global keypassthru for KeyPaSsThRu
	forvalues k=1/`key_count' {
		KeyPaSsThRu, str(`key`k'')
	}

	local keys "$KeYpAsStHrU_____"    // global key1 --> local keys
	macro drop KeYpAsStHrU_____

if `or_recode'==1 {
	****************************************************************
	*** Check if user recoding rules are into the possible range ***
	****************************************************************
	local strip_comma_user_rules: subinstr local user_rules "," " ", all
	forvalues i = 1/`nr' {
		local check_rule`i': word `i' of `strip_comma_user_rules'
		if `check_rule`i'' > `key_count' {
			noi di as error "-recode()- option: recoding rules cannot exceed keywords' number (`check_rule`i'' > `key_count' keywords)."
			error 198
			exit
		}
	}
}

****************************************************************
*************** WARNING IF KEYWORDS AND SOURCE *****************
******* ARE UNMACHABLE DUE TO UPPER/LOWER CASE PROBLEMS ********
****************************************************************

if (`opt_sources1'==0 & `opt_sources2'==0) & "`nowarnings'"=="" {
	foreach s of loc sources {
		forvalues i=1/`key_count' {

			CaNgOaHeAd, tocheck(`key`i'')
			if $CaNgOaHeAd_____==0 continue
			macro drop CaNgOaHeAd_____

			local lower_upper_`i' = lower("`key`i''")
			capture assert "`lower_upper_`i''" == "`key`i''"
				if _rc!=0 {
					local lower_upper_`i' "1"
				}
				else local lower_upper_`i' "0"
			if (`lower_upper_`i'' == 1 & `lower_upper_`s'' == 0)  	{
				di ""
				di in yellow "WARNING: You are matching the UPPERCASE keyword " in green "`key`i''" in yellow " with the LOWERCASE source " in green "`s'" in yellow "."
			}
			if (`lower_upper_`i'' == 0 & `lower_upper_`s'' == 1)  	{
				di ""
				di in yellow "WARNING: You are matching the LOWERCASE keyword " in green "`key`i''" in yellow " with the UPPERCASE source " in green "`s'" in yellow "."
			}
		}
	}
}

****************************************************************
*************** SOURCES' SUBOPTION: LOWER & UPPER **************
****************************************************************

local sources_new ""
if (`opt_sources1'==1 | `opt_sources2'==1) {

	if (`opt_sources1'==1) {
		foreach s of loc sources {
			tempvar lower_var`s'
			qui gen str`length_source_`s'' `lower_var`s''=lower(`s')
			local keys = lower("`keys'")
			forvalues i=1/`key_count' {
				local key`i' = lower("`key`i''")
			}
			local sources_new "`sources_new' `lower_var`s''"
		}
	}
	if (`opt_sources2'==1) {
		foreach s of loc sources {
			tempvar upper_var`s'
			qui gen str`length_source_`s'' `upper_var`s''=upper(`s')
			local keys = upper("`keys'")
			forvalues i=1/`key_count' {
				local key`i' = upper("`key`i''")
			}
			local sources_new "`sources_new' `upper_var`s''"
		}
	}
}
else {
	local sources_new "`sources'"
}

***************************************************************************
********* SOURCES' SUBOPTION: TRIM, REMOVEBLANK & REMOVESIGN **************
***************************************************************************
*** NOTE: the executions' order of suboptions is very important. Do not change it!

if "`opt_sources'"!=""  {

	if (`opt_sources5'==1) {
		local sources_new_removeblank ""
		foreach s of loc sources_new {
			tempvar removeblank_var`s'
			qui gen `removeblank_var`s''= subinstr(`s', " ", "", .)
			local sources_new_removeblank "`sources_new_removeblank' `removeblank_var`s''"
		}
		local sources_new "`sources_new_removeblank'"
	}
	if (`opt_sources6'==1) {
		local sources_new_removesign ""
		foreach s of loc sources_new {
			tempvar removesign_var`s'
			qui gen `removesign_var`s'' = `s'
			CLeanSegniVariable, toc(`removesign_var`s'')
			local sources_new_removesign "`sources_new_removesign' `removesign_var`s''"
		}
		local sources_new "`sources_new_removesign'"
	}
	if (`opt_sources3'==1) {
		local sources_new_trim ""
		foreach s of loc sources_new {
			tempvar trimmed_var`s'
			qui gen `trimmed_var`s''=trim(`s')
			local sources_new_trim "`sources_new_trim' `trimmed_var`s''"
		}
		local sources_new "`sources_new_trim'"
	}
	if (`opt_sources4'==1) {
		local sources_new_itrim ""
		foreach s of loc sources_new {
			tempvar itrimmed_var`s'
			qui gen `itrimmed_var`s''=itrim(`s')
			local sources_new_itrim "`sources_new_itrim' `itrimmed_var`s''"
		}
		local sources_new "`sources_new_itrim'"
	}

}

****************************************************************
*******************  MATA SET-UP  ******************************
****************************************************************

**** Create NULL matrix for subsequent use
mata: tot_match = J(`all_obs',0,.)

****************************************************************
******************** OPTION LETTERS ****************************
****************************************************************

if "`letters'"!="" {
	local nletters: word count `letters'
	if `nletters'!=`key_count' {
		di in red as error "Option -letters- must contains as many numbers as the number of keys"
		error 198
	}

	forvalues i=1/`key_count' {
		local key`i' = regexr("`key`i''", "\^", "")
		local key`i' = regexr("`key`i''", "[\$]", "")
		local extract`i': word `i' of `letters'

		*** Fix the case in which local extract is greater than effective length of key
		if `extract`i'' <= length("`key`i''") & `key`i'_is_a_regexpr'==0 {
			 local key`i' = substr("`key`i''", 1, `extract`i'' )
		}

		if regexm("`w`i''", "\^")==1  local key`i' "^`key`i''"
		if regexm("`w`i''", "[\$]")==1  local key`i' "`key`i''$"
	}
}


****************************************************************
*** WARNINGS IF SOURCE VARIABLES CONTAINS REG EXPR OPERATORS ***
****************************************************************

if "`checksources'"!="" {
	local jj=0
	foreach s of loc sources_new {
		local jj=`jj'+1
		local labelling: word `jj' of `sources'
		label var `s' "`labelling'"

		forvalues i=1/`key_count' {

			tempvar _____checking_sign
			local begin=regexm("`key`i''","\^")
			local end=regexm("`key`i''","[\$]")
			CHangeSegni `s' if `touse'==1, generate(`_____checking_sign') check(`s') b(`begin') e(`end')
			qui sum `_____checking_sign' if `touse'==1
			if r(max)!=0 {					// If _____checking_sign !=0 => r(max)>0 => Some changes are troublesome

				if "`begin'"=="0" & "`end'"=="0" & `i'==`key_count' {
					di ""
					di in yellow "WARNING: The source variable " in green "`labelling'" in yellow " contain special characters other than letters."
					if "`tabcheck'"!="" {
						capture noi tab `s' if `_____checking_sign' > 0 & `touse'==1, sort
						if _rc!=0 {
							noi di in red "Too many cases -- table not shown."
						}
					}
				}
				if "`begin'"=="1" {
					di ""
					di in yellow "WARNING: The variable " in green "`labelling'" in yellow " contains characters other than letters placed at beginning of the string."
					di in yellow "	       By matching keyword " in green regexr("`key`i''", "\^", "") in yellow " at beginning of " in green "`labelling'" in yellow ", these cases could not be identified."
					di in yellow "         Screening may not work as expected."
					if "`tabcheck'"!="" {
						capture noi tab `s' if `_____checking_sign' > 0 & `touse'==1, sort
						if _rc!=0 {
							noi di in red "Too many cases -- table not shown."
						}
					}
				}
				if "`end'"=="1" {
					di ""
					di in yellow "WARNING: The variable " in green "`labelling'" in yellow " contains characters other than letters placed at the end of the string."
					di in yellow "	       By matching keyword " in green regexr("`key`i''", "[\$]", "") in yellow " at the end of " in green "`labelling'" in yellow ", these cases could not be identified."
					di in yellow "         Screening may not work as expected."
					if "`tabcheck'"!="" {
						capture noi tab `s' if `_____checking_sign' > 0 & `touse'==1, sort
						if _rc!=0 {
							noi di in red "Too many cases -- table not shown."
						}
					}
				}
			}
			else {
				if "`tabcheck'"!="" {
					di ""
					di in yellow "The variable " in green "`labelling'" in yellow " do not contains special characters."
					di in yellow "-tabcheck- option cannot be executed."
				}
			}
		drop `_____checking_sign'
		}
	}
}

****************************************************************
**** INITIALIZE NEWCODE & TMP_NEWCODE IF REGEXS ****************
****************************************************************

if "`newcode'"!="" & `opt_newcode2'==0 & `or_recode'==0 {
	qui gen byte `newcode' = .
}

if "`newcode'"!="" & `opt_newcode2'==0 & `or_recode'==1 {
	qui gen /*str`max_sources_length'*/ `newcode' = ""
}

if "`newcode'"!="" & `opt_newcode2'==1 & `or_recode'==0 {
	tempvar tmp_newcode_replace
	qui gen byte `tmp_newcode_replace' = .
	if "`nowarnings'"=="" {
		di ""
		di in yellow "WARNING: By specifying " in green "-replace-" in yellow " sub-option you are overwriting the " in green "-newcode()-" in yellow " variable."
	}
}

if "`newcode'"!="" & `opt_newcode2'==1 & `or_recode'==1 {
	tempvar tmp_newcode_replace
	qui gen /*str`max_sources_length'*/ `tmp_newcode_replace' = ""
	if "`nowarnings'"=="" {
		di ""
		di in yellow "WARNING: By specifying " in green "-replace-" in yellow " sub-option you are overwriting the " in green "-newcode()-" in yellow " variable."
	}
}

*** Create tmp_newcode to be used after execution of related mata functions
if `nsregexs_yes'!=0 {
	tempvar tmp_newcode
	qui gen /*str`max_sources_length'*/ `tmp_newcode' = ""
}

****************************************************************
******************** MATA SCREEN() FUNCTION ********************
****************************************************************

*** Just for time saving

if "`save'"=="" & "`explore'"=="" & `regexpr_screen'==0  local yes_tmp_sj "0"
else local yes_tmp_sj "1"

if "`newcode'"=="" & "`cases'"=="" & `or_recode'==0  local yes_cases "0"
else {
	local yes_cases "1"
	local du_names_list ""
	forvalues i=1/`key_count' {

		local j "`i'"
		local j_name "`i'"
		tempvar tmp_`j_name'
		qui gen byte `tmp_`j_name'' = .
  		label var `tmp_`j_name'' "`key`i''"
		local du_names_list "`du_names_list' `tmp_`j_name''"
	}
}

*** MATA screening

local ss "0"
foreach s of loc sources_new {
	local ss = `ss'+1
	local esample_obs_for_tab_`ss' "0"

	forvalues i=1/`key_count' {

		**** Creates tmp variable for tabulation
		if `yes_tmp_sj' == 1  {

			local j "`i'"
			local j_name "`i'"
			tempvar `s'_`j_name'
			local or_source_name: word `ss' of `sources'
			qui gen str`length_source_`or_source_name'' ``s'_`j_name'' = ""
  			label var ``s'_`j_name'' "`j'"
		}
		else local `s'_`j_name' "``s'_`j_name''"
		*************************************************************************
		noi mata: screen("`s'", "`key`i''", "``s'_`j_name''", `ss' , `i', `key_count', `nsources', "`du_names_list'", `check_strL')
		*************************************************************************
		if `yes_tmp_sj' == 1  {
			qui count if ``s'_`j_name''!="" & `touse'==1
			local esample_obs_for_tab_`ss' = `esample_obs_for_tab_`ss'' + r(N)
		}
	}
}

****************************************************************
************* OPTION CASES AND NEWCODE *************************
****************************************************************

if "`newcode'"!="" & `or_recode'==0 {

	forvalues i=1/`key_count' {

				local j "`i'"
				local j_name "`i'"

	if `opt_newcode2'==0	qui replace `newcode' = `j' if `tmp_`j_name'' > 0 & `newcode'==. & `touse'==1
	else qui replace `tmp_newcode_replace' = `j' if `tmp_`j_name'' > 0 & `tmp_newcode_replace'==. & `touse'==1
	}
	*** FIX in the case of suboption replace within newcode()
	if `opt_newcode2'==1 {
		tempvar tmp_rep_replace
		qui gen byte `tmp_rep_replace' = (`tmp_newcode_replace'!=.) if `touse'==1
		qui replace `newcode' = `tmp_newcode_replace' if `tmp_rep_replace'==1 & `touse'==1
	}
}

if "`cases'"!=""  {

	forvalues i=1/`key_count' {

		local j "`i'"
		local j_name "`i'"

		capture confirm new variable `cases'_key`j_name'
		if _rc!=0 {
			noi di in red as error "Variable `cases'_key`j_name' is already defined."
			error 110
		}
		**** Generates cases variable to be used by mata function -cases()-
		qui gen byte `cases'_key`j_name' = `tmp_`j_name'' if `touse'==1
		if `j_name' == 1  local order "st"
		if `j_name' == 2  local order "nd"
		if `j_name' == 3  local order "rd"
		if `j_name' > 3  local order "th"
		label var `cases'_key`j_name' "Occurrences of `j_name'`order' keyword"
	}
}

****************************************************************
************************* OPTION RECODE ************************
****************************************************************

if "`newcode'"!="" & `or_recode'==1 {

	forvalues kk=1/`nr' {

		if "`nsregexs_yes_`kk''"=="1" {

			local r_r: word `kk' of `user_rules'

			*************************************************************************
			if ("`sregexs_`kk''"!="") noi mata: screen_regexs("`sources_new'", "`key`r_r''", "`tmp_newcode'", `sregexs_`kk'' , `check_strL')
			if ("`sregexs_`kk''"!="" & "`prefix_sregexs_`kk''"!="") noi mata: screen_regexs_prefix("`sources_new'", "`key`r_r''", "`tmp_newcode'", `sregexs_`kk'', "`prefix_sregexs_`kk''", `check_strL' )
			if ("`sregexs_`kk''"!="" & "`postfix_sregexs_`kk''"!="") noi mata: screen_regexs_postfix("`sources_new'", "`key`r_r''", "`tmp_newcode'", `sregexs_`kk'', "`postfix_sregexs_`kk''", `check_strL' )
			*************************************************************************

			*** Recoding when there is a regexs() function within recode()
			if (`opt_newcode1'==0 & `opt_newcode2'==0 & `kk'==1 )  qui replace `newcode'=`tmp_newcode' if `touse'==1
			if (`opt_newcode1'==1 & `opt_newcode2'==0 & `kk'==1 )  qui replace `newcode'=`tmp_newcode' if `touse'==1
			if (`opt_newcode1'==0 & `opt_newcode2'==1 & `kk'==1 )  qui replace `tmp_newcode_replace'=`tmp_newcode' if `touse'==1
			if (`opt_newcode1'==1 & `opt_newcode2'==1 & `kk'==1 )  qui replace `tmp_newcode_replace'=`tmp_newcode' if `touse'==1

			if (`opt_newcode1'==1 & `opt_newcode2'==0 & `kk'>1)    qui replace `newcode'=`newcode' + `tmp_newcode' if `touse'==1
			if (`opt_newcode1'==0 & `opt_newcode2'==1 & `kk'>1)    qui replace `tmp_newcode_replace'=`tmp_newcode' if `newcode'=="" & `touse'==1
			if (`opt_newcode1'==1 & `opt_newcode2'==1 & `kk'>1)    qui replace `tmp_newcode_replace'=`tmp_newcode_replace' + `tmp_newcode' if `touse'==1
			if (`opt_newcode1'==0 & `opt_newcode2'==0 & `kk'>1)    qui replace `newcode'=`tmp_newcode' if `newcode'==""	& `touse'==1
		}
		else  {

			local subrule: word `kk' of `user_rules'
			local subrule: subinstr local subrule "," " ",all
			local nsubrules: word count `subrule'
			local rec_rule_`kk' ""
			forvalues kk1=1/`nsubrules' {
				local subrule`kk1': word `kk1' of `subrule'

				local j "`subrule`kk1''"
				local j_name "`subrule`kk1''"

				if `opt_newcode2'==0 local rec_rule_`kk' "`rec_rule_`kk'' `tmp_`j_name''>0 "
				if `opt_newcode2'==1 local rec_rule_`kk' "`rec_rule_`kk'' `tmp_`j_name''>0 "

				if `kk1'<`nsubrules' {
					local rec_rule_`kk' "`rec_rule_`kk'' & "
				}
			}

			*** Fix recoding rules
			if (`opt_newcode2'==0 & `opt_newcode1'==0) local rec_rule_`kk' "if `rec_rule_`kk'' & `newcode'=="" & `touse'==1"
			if (`opt_newcode2'==1 & `opt_newcode1'==0) local rec_rule_`kk' "if `rec_rule_`kk'' & `tmp_newcode_replace'=="" & `touse'==1"
			if (`opt_newcode1'==1) local rec_rule_`kk' "if `rec_rule_`kk'' & `touse'==1"

			*** Recoding when there is NO a regexs() function within recode()
			if (`opt_newcode1'==0 & `opt_newcode2'==0 & `kk'==1 )  qui replace `newcode' = "`user_rule_`kk''" `rec_rule_`kk''
			if (`opt_newcode1'==1 & `opt_newcode2'==0 & `kk'==1 )  qui replace `newcode' = "`user_rule_`kk''" `rec_rule_`kk''
			if (`opt_newcode1'==0 & `opt_newcode2'==1 & `kk'==1 )  qui replace `tmp_newcode_replace' = "`user_rule_`kk''" `rec_rule_`kk''
			if (`opt_newcode1'==1 & `opt_newcode2'==1 & `kk'==1 )  qui replace `tmp_newcode_replace' = "`user_rule_`kk''" `rec_rule_`kk''

			if (`opt_newcode1'==1 & `opt_newcode2'==0 & `kk'>1)    qui replace `newcode' = `newcode' + "`user_rule_`kk''" `rec_rule_`kk''
			if (`opt_newcode1'==0 & `opt_newcode2'==1 & `kk'>1)    qui replace `tmp_newcode_replace' = "`user_rule_`kk''" `rec_rule_`kk''
			if (`opt_newcode1'==1 & `opt_newcode2'==1 & `kk'>1)    qui replace `tmp_newcode_replace' = `tmp_newcode_replace' + "`user_rule_`kk''" `rec_rule_`kk''
			if (`opt_newcode1'==0 & `opt_newcode2'==0 & `kk'>1)    qui replace `newcode' = "`user_rule_`kk''" `rec_rule_`kk''

		}
	}

	*** FIX in the case of suboption replace within newcode()
	if `opt_newcode2'==1 {
		tempvar tmp_rep1_replace
		qui gen byte `tmp_rep1_replace' = (`tmp_newcode_replace'!="") if `touse'==1
		qui replace `newcode' = `tmp_newcode_replace' if `tmp_rep1_replace'==1 & `touse'==1
	}

}

****************************************************************
************************* OPTION SAVE **************************
****************************************************************

if "`save'" != ""  {
	local jj=0
	foreach s of loc sources_new {
	local jj=`jj'+1
		forvalues i=1/`key_count' {

			local j "`i'"
			local j_name "`i'"

			if "`newcode'"=="" & ( "`cases'"!="" | "`explore'"!="" ) {
				qui count if ``s'_`j_name''!="" & `touse'==1
				ret scalar key`i'_source`jj' = r(N)
			}

			if "`newcode'"!="" &  "`cases'"=="" & "`explore'"=="" & `or_recode'==0 {
			 	qui count if `newcode' == `i' & `touse'==1
				ret scalar newcode_`i' = r(N)

			}
			if "`newcode'"!="" &  ("`cases'"!="" | "`explore'"!="") & `or_recode'==0 {

				qui count if ``s'_`j_name''!="" & `touse'==1
				ret scalar key`i'_source`jj' = r(N)
				qui count if `newcode' == `i' & `touse'==1
				ret scalar newcode_`i' = r(N)

			}
			if "`newcode'"!="" & "`cases'"=="" & "`explore'"=="" & `or_recode'==1 & `nsregexs_yes'==0 {

				tempvar n
				qui gen byte `n'=1 if `touse'==1

				qui tab `newcode' if `touse'==1
				local max = r(r)
				forvalues iiii=1/`max' {
					qui count if `newcode' == "`user_rule_`iiii''" & `touse'==1
					loc stats`iiii' = r(N)
				}
				qui tabstat `n' if `touse'==1, by(`newcode') stats(n) save
				forvalues iiiii=1/`max' {
					ret scalar newcode_`iiiii' = `stats`iiiii''
				}
			}

			if "`newcode'"!="" & ("`cases'"!="" | "`explore'"!="") & `or_recode'==1 & `nsregexs_yes'==0 {

				qui count if ``s'_`j_name''!="" & `touse'==1
				ret scalar key`i'_source`jj' = r(N)

				tempvar n
				qui gen byte `n'=1 if `touse'==1

				qui tab `newcode' if `touse'==1
				local max = r(r)
				forvalues iiii=1/`max' {
					qui count if `newcode' == "`user_rule_`iiii''" & `touse'==1
					loc stats`iiii' = r(N)
				}
				qui tabstat `n' if `touse'==1, by(`newcode') stats(n) save
				forvalues iiiii=1/`max' {
					ret scalar newcode_`iiiii' = `stats`iiiii''
				}
			}
		}
	}
}

**** Timer OFF

if "`time'"!="" {
	timer off 1
	.`time' = ._tab.new, col(2) lmargin(0)
	.`time'.width  20 | 12
	.`time'.titlefmt  %19s  %11s
    .`time'.pad       2  2
    .`time'.numfmt    . %9.2f
	di ""
	.`time'.sep, top
	.`time'.titles "Elapsed time" "Seconds"
	.`time'.sep, middle
	qui timer list
	.`time'.row  "Total" r(t1)
	.`time'.row  "Screening" r(t2)
	.`time'.sep, bottom
	ret scalar tot_time = r(t1)
	ret scalar screen_time = r(t2)
}

****************************************************************
********* Tabulate report and relative matched cases ***********
****************************************************************

if "`explore'" != "" {
	local key_length_list "0"
	if "`letters'" != "" {
		forvalues i=1/`key_count' {
			local key`i'_length = length("`key`i''")
			local key_length_list "`key_length_list' `key`i'_length'"
			loc let_comma: subinstr local key_length_list " " ",", all
		}
		loc let_max = max(`let_comma') + 2
		loc display_let = `let_max'-1
	}
	else {
		forvalues i=1/`key_count' {
			local key`i'_length: word `i' of `allkey'
			local key`i'_length = length("`key`i'_length'")
			local key_length_list "`key_length_list' `key`i'_length'"
			loc let_comma: subinstr local key_length_list " " ",", all
		}
		loc let_max = max(`let_comma') + 2
		loc display_let = `let_max'-1
	}
	if "`explore'" == "count" {
		.`explore' = ._tab.new, col(4) lmargin(0)
		.`explore'.width  20 | `let_max' | 12 | 9
		.`explore'.titlefmt  %19s  %`display_let's  %11s %8s
	    .`explore'.pad       2  2  2  2
	    .`explore'.numfmt    . 	. %9.0g %6.2f
		di ""
		.`explore'.titles "Source" "Key"  "Freq." "Percent"
		.`explore'.sep, middle
	}

	local jj=0
	foreach s of loc sources_new {
	local jj=`jj'+1
	local labelling: word `jj' of `sources'

		forvalues i=1/`key_count' {

			local j_name "`i'"
			if "`letters'" == "" {
				local j: word `i' of `allkey'
				label var ``s'_`j_name'' "`j'"
			}
			else {
				local j "`key`i''"
				label var ``s'_`j_name'' "`j'"
			}

			if "`explore'" == "tab" {
				di ""
				di in yel "Cases of " in gr "`j'" in yel " found in " in gr "`labelling'"
				tab ``s'_`j_name'' if `touse'==1, sort
				di ""
			}
			else if "`explore'" == "count" {
				if `i'==1 {

					local abb_source = abbrev("`labelling'", 20)
					qui count if ``s'_`j_name''!="" & `touse'==1
					.`explore'.strfmt    %19s  .  .  .
					.`explore'.row  "`abb_source'" "`j'" r(N) r(N)/`esample_obs_for_tab_`jj''*100
				}
				else {
					qui count if ``s'_`j_name''!="" & `touse'==1
					.`explore'.strfmt    %19s  %`display_let's  .	.
					.`explore'.row  "" "`j'" r(N) r(N)/`esample_obs_for_tab_`jj''*100
				}
			}
			if `i' == `key_count' & "`explore'" == "count"  {
						.`explore'.sep, middle
						.`explore'.row  "" "Total" `esample_obs_for_tab_`jj'' 100.00
						di ""

			}
		}
	}
}

****************************************************************
*************** OPTION NEWCODE: SUBOPTION NUMERIC **************
****************************************************************

if `opt_newcode4'==1 & `or_recode'==1 {
	qui capture destring `newcode', replace
	capture confirm str variable `newcode'
	if _rc==0 {
		if "`nowarnings'"=="" {
			di ""
			di in yellow "WARNING: sub-option -numeric- cannot be executed since " in green "`newcode'" in yellow " contains non-numeric characters."
		}
	}
}

if `or_recode'==0 & `opt_newcode3'==1 {
	label values `newcode' `newcode'_key_label
}

end /* End of the ADO code */


****************************************************************
******************** ANCILLARY FUNCTIONS ***********************
****************************************************************

****************************************************************
********************** MATA FUNCTIONS **************************
****************************************************************

/// MATA FUNCTIONS TO SCREEN

mata
function screen(source, key, tmp_mcases, ss, ii, nkey, nsources, du_names_list, check_strL)
{
external tot_match
if (check_strL==1) source = st_sdata(., tokens(source))
else st_sview(source,.,source)

n = rows(source)
mcases = J(n,1,"")
yes = st_local("yes_tmp_sj")
yes_cases = st_local("yes_cases")

timer_on(2)
/// Screening
match = ustrregexm(source, key)

if (yes == "1") {
	for(i=1; i<=n; i++)	{
		if (match[i,1]:==1)  	mcases[i,1] = source[i,1]
		else 					mcases[i,1] = ""
	}
}

// tot_match for cases() function
tot_match = (tot_match, match)
// Option explore
if (yes == "1") st_sstore(., tmp_mcases, mcases)

if ((ss == nsources) & (ii == nkey) & (yes_cases=="1")) {
	du_names = tokens(du_names_list)
		for (iii=1; iii<=nkey; iii++) {
			dummy = J(rows(tot_match),1,.)
			dummy = tot_match[.,iii]
				for (j=1; j<=nsources-1; j++) {
					dummy=dummy+tot_match[.,(nkey*j+iii)]
				}
	st_store(., du_names[1,iii], dummy)
		}
}
timer_off(2)

}


function screen_regexs(source, key, tmp_newcode, real scalar lregexs, check_strL)
{
if (check_strL==1) source = st_sdata(., tokens(source))
else st_sview(source,.,source)
n = rows(source)

/// Screening with regexs
exs_match = J(n,1,"")
	for(i=1; i<=n; i++) {
		if (ustrregexm(source[i], key)) exs_match[i] = ustrregexs(lregexs)
	}
st_sstore(., tmp_newcode, exs_match)

}


function screen_regexs_prefix(source, key, tmp_newcode, real scalar lregexs, prefix_regexs, check_strL)
{
if (check_strL==1) source = st_sdata(., tokens(source))
else st_sview(source,.,source)
n = rows(source)

/// Screening with regexs and prefix
exs_match = J(n,1,"")
	for(i=1; i<=n; i++) {
		if (ustrregexm(source[i], key)) exs_match[i] = prefix_regexs + ustrregexs(lregexs)
		}
st_sstore(., tmp_newcode, exs_match)

}

function screen_regexs_postfix(source, key, tmp_newcode, real scalar lregexs, postfix_regexs, check_strL)
{
if (check_strL==1) source = st_sdata(., tokens(source))
else st_sview(source,.,source)
n = rows(source)

/// Screening with regexs and prefix
exs_match = J(n,1,"")
	for(i=1; i<=n; i++) {
		if (ustrregexm(source[i], key)) exs_match[i] = ustrregexs(lregexs) + postfix_regexs
		}
st_sstore(., tmp_newcode, exs_match)

}

end

****************************************************************
************************* UTILITY ******************************
****************************************************************

****************************************************************
*	CLEAN FROM REGULAR EXPRESSION OPERATORS
****************************************************************

program define CLeanSegni
	syntax, TOClean(string)
qui {
local j = subinstr("`toclean'", "*", "",.)
local j = subinstr("`j'", "+", "",.)
local j = subinstr("`j'", "?", "",.)
local j = subinstr("`j'", "/", "",.)
local j = subinstr("`j'", "\", "",.)
local j = subinstr("`j'", "%", "",.)
local j = subinstr("`j'", "(", "",.)
local j = subinstr("`j'", ")", "",.)
local j = subinstr("`j'", "[", "",.)
local j = subinstr("`j'", "]", "",.)
local j = subinstr("`j'", "{", "",.)
local j = subinstr("`j'", "}", "",.)
local j = subinstr("`j'", "|", "",.)
local j = subinstr("`j'", ".", "",.)
local j = subinstr("`j'", "^", "",.)
local j = subinstr("`j'", "-", "",.)
local j = subinstr("`j'", "_", "",.)
local j = subinstr("`j'", "$", "",.)
local j = subinstr("`j'", "#", "",.)
global ClEaNsEgNi_____  "`j'"

}
end

program define CaNgOaHeAd
	syntax, TOCHECK(string) [VARNAME]
qui {
capture confirm names `tocheck'
if _rc==0 {
	if "`varname'" != "" {
		local le = length("`tocheck'")
		if `le'<= 20 	global CaNgOaHeAd_____ "1"
		else global CaNgOaHeAd_____ "0"
	}
	else global CaNgOaHeAd_____ "1"
}
else global CaNgOaHeAd_____ "0"
}
end

program define CLeanSegniVariable
	syntax, TOClean(name)
qui {
replace `toclean' = subinstr(`toclean', "*", "",.)
replace `toclean' = subinstr(`toclean', "+", "",.)
replace `toclean' = subinstr(`toclean', "?", "",.)
replace `toclean' = subinstr(`toclean', "/", "",.)
replace `toclean' = subinstr(`toclean', "\", "",.)
replace `toclean' = subinstr(`toclean', "%", "",.)
replace `toclean' = subinstr(`toclean', "(", "",.)
replace `toclean' = subinstr(`toclean', ")", "",.)
replace `toclean' = subinstr(`toclean', "[", "",.)
replace `toclean' = subinstr(`toclean', "]", "",.)
replace `toclean' = subinstr(`toclean', "{", "",.)
replace `toclean' = subinstr(`toclean', "}", "",.)
replace `toclean' = subinstr(`toclean', "|", "",.)
replace `toclean' = subinstr(`toclean', ".", "",.)
replace `toclean' = subinstr(`toclean', "^", "",.)
replace `toclean' = subinstr(`toclean', "-", "",.)
replace `toclean' = subinstr(`toclean', "_", "",.)
replace `toclean' = subinstr(`toclean', "$", "",.)
replace `toclean' = subinstr(`toclean', "#", "",.)
}
end

****************************************************************
*	CHECK REGULAR EXPRESSION OPERATORS
****************************************************************


program define CHeckSegni
	syntax,  CHECK(string) NUM(string)
qui {

	local CHeckSegni`num'___ "0"
	local CHeckSegni`num'___ = `CHeckSegni`num'___' + regexm("`check'", "\*")
	local CHeckSegni`num'___ = `CHeckSegni`num'___' + regexm("`check'", "\+")
	local CHeckSegni`num'___ = `CHeckSegni`num'___' + regexm("`check'", "\?")
	local CHeckSegni`num'___ = `CHeckSegni`num'___' + regexm("`check'", "\(")
	local CHeckSegni`num'___ = `CHeckSegni`num'___' + regexm("`check'", "\)")
	local CHeckSegni`num'___ = `CHeckSegni`num'___' + regexm("`check'", "\[")
	local CHeckSegni`num'___ = `CHeckSegni`num'___' + regexm("`check'", "\]")
	local CHeckSegni`num'___ = `CHeckSegni`num'___' + regexm("`check'", "\|")
	local CHeckSegni`num'___ = `CHeckSegni`num'___' + regexm("`check'", "\.")
    local CHeckSegni`num'___ = `CHeckSegni`num'___' + regexm("`check'", "\^")
	local CHeckSegni`num'___ = `CHeckSegni`num'___' + regexm("`check'", "\\\")
	global CHeckSegni___ "`CHeckSegni`num'___'"
}
end


*************************************************************************
*	CHECK IF CHARACTERS OTHER THAN LETTER AT BEGINNING AND END OF STRING
*************************************************************************

program define CHangeSegni
	syntax name [if] [in], GENerate(string) CHECK(string) [ Bsr(real 9) Esr(real 9) ]
	marksample use, strok
	if `bsr'==1  local beg "^"
	if `esr'==1  local end1 "$"
qui {
	gen byte `generate'=0	if `use'==1
	replace `generate' = `generate'+regexm(`check', "`beg'\*`end1'") if `use'==1
	replace `generate' = `generate'+regexm(`check', "`beg'\+`end1'") if `use'==1
	replace `generate' = `generate'+regexm(`check', "`beg'\?`end1'") if `use'==1
	replace `generate' = `generate'+regexm(`check', "`beg'/`end1'") if `use'==1
	replace `generate' = `generate'+regexm(`check', "`beg'\\\`end1'") if `use'==1
	replace `generate' = `generate'+regexm(`check', "`beg'%`end1'") if `use'==1
	replace `generate' = `generate'+regexm(`check', "`beg'\(`end1'") if `use'==1
	replace `generate' = `generate'+regexm(`check', "`beg'\)`end1'")	if `use'==1
	replace `generate' = `generate'+regexm(`check', "`beg'\[`end1'") if `use'==1
	replace `generate' = `generate'+regexm(`check', "`beg'\]`end1'")	if `use'==1
	replace `generate' = `generate'+regexm(`check', "`beg'{`end1'")	if `use'==1
	replace `generate' = `generate'+regexm(`check', "`beg'}`end1'")	if `use'==1
	replace `generate' = `generate'+regexm(`check', "`beg'\|`end1'")	if `use'==1
	replace `generate' = `generate'+regexm(`check', "`beg'\.`end1'")	if `use'==1
	replace `generate' = `generate'+regexm(`check', "`beg'-`end1'")	if `use'==1
	replace `generate' = `generate'+regexm(`check', "`beg'_`end1'")	if `use'==1
	replace `generate' = `generate'+regexm(`check', "`beg'#`end1'")	if `use'==1
	replace `generate' = `generate'+regexm(`check', "`beg'[\$]`end1'")	if `use'==1
*** ATT: Can numbers be considered a tedius sign? I think NO
***	replace `generate' = `generate'+regexm(`check', "`beg'[0-9]`end1'")	if `use'==1

}
end

*************************************************************************
*	SUBSTRING FROM PASSTHRU
*************************************************************************

prog define SUBpassTHRU, rclass
	syntax, p(passthru) [n(real 9)]
	local n=`n'+3
		forvalues i=3(1)`n' {
			return local tmp`i' "``i''"
		}
end

*************************************************************************
*	UNION OF TRUE KEY USING PASSTHRU
*   note: the output is a global
*************************************************************************

prog define KeyPaSsThRu
syntax, str(passthru)
local ktmp=regexr(`"`str'"', "\)$", " ")
local ktmp: subinstr local ktmp "str(" " ", all
global KeYpAsStHrU_____  "$KeYpAsStHrU_____ `ktmp'"
end

*************************************************************************
*	CHECKMEM
*   note: It is very useful with large datasets
*************************************************************************

program define checkmem
	version 8.0
	syntax, [ VINT(integer 0) VLONG(integer 0) VDOUBLE(integer 0) VBYTE(integer 0)  VSTR(string) ///
		    MREAL1(string) MCOMPLEX1(string) MSTR1(string)  ///
			MREAL2(string) MCOMPLEX2(string) MSTR2(string)  ///
			MREAL3(string) MCOMPLEX3(string) MSTR3(string)  ///
			MREAL4(string) MCOMPLEX4(string) MSTR4(string)  ///
			MREAL5(string) MCOMPLEX5(string) MSTR5(string)  ///
			MREAL6(string) MCOMPLEX6(string) MSTR6(string)  ///
			MREAL7(string) MCOMPLEX7(string) MSTR7(string)  ///
			MREAL8(string) MCOMPLEX8(string) MSTR8(string)  ///
			MREAL9(string) MCOMPLEX9(string) MSTR9(string)  ///
			MREAL10(string) MCOMPLEX10(string) MSTR10(string) ]

	local memcheck "memcheck"
	qui des
	local init_data_size = int((r(width)/r(k))*r(N)*r(k) + 4 * r(N)) + 20 * r(k)
    local N = r(N)
	qui memory
	local total_all_mem = r(M_total)/(1024^2)

	*** Parsing of string variables
	gettoken var_length_str var_number_str: vstr, parse(",")
	local var_number_str: subinstr local var_number_str "," ""

	local max_real "0"
	local max_compl "0"
	local max_str "0"

	forvalues i = 1/10 {
		if "`mreal`i''"!="" local max_real = `i'
		if "`mcomplex`i''"!="" local max_compl = `i'
		if "`mstr`i''"!="" local max_str = `i'
	}
	*** Parsing of matrix types
	if `max_real'!=0 {
		forvalues i = 1/`max_real' {
			gettoken mat_row_real`i' mat_col_real`i': mreal`i', parse(",")
			local mat_col_real`i': subinstr local mat_col_real`i' "," ""
		}
	}
	if `max_compl'!=0 {
		forvalues i = 1/`max_compl' {
			gettoken mat_row_compl`i' mat_col_compl`i': mcomplex`i', parse(",")
			local mat_col_compl`i': subinstr local mat_col_compl`i' "," ""
		}
	}
	if `max_str'!=0 {
		forvalues i = 1/`max_str' {
			gettoken mat_length_str`i' mat_dim_str`i': mstr`i', parse(",")
			local mat_dim_str`i': subinstr local mat_dim_str`i' "," ""
			gettoken mat_row_str`i' mat_col_str`i': mat_dim_str`i', parse(",")
			local mat_col_str`i': subinstr local mat_col_str`i' "," ""
		}
	}
		**** Initialize width
		local types "vint vbyte vlong vdouble vstr mreal mcompl mstr"
		foreach x of local types {
			local width_`x' "0"
		}
		**** Compute required memory
		if "`vint'"!="" {
			local width_vint = 2*`N'*`vint'
		}
		if "`vbyte'"!="" {
			local width_vbyte = `N'*`vbyte'
		}
		if "`vlong'"!="" {
			local width_vlong = `N'*4*`vlong'
		}
		if "`vdouble'"!="" {
			local width_vdouble = `N'*8*`vdouble'
		}
		if "`vstr'"!="" {
			confirm integer number `var_length_str'
			local width_vstr = `N'*`var_length_str'*`var_number_str'
		}
		if `max_real'!=0 {
			forvalues i = 1/`max_real' {
				confirm integer number `mat_row_real`i''
				confirm integer number `mat_col_real`i''
				local width_mreal = `width_mreal' + 64 + 8*`mat_row_real`i''*`mat_col_real`i''
			}
		}
		if `max_compl'!=0 {
			forvalues i = 1/`max_compl' {
				confirm integer number `mat_row_compl`i''
				confirm integer number `mat_col_compl`i''
				local width_mcompl = `width_mcompl' + 64 + 16*`mat_row_compl`i''*`mat_col_compl`i''
			}
		}
		if `max_str'!=0 {
			forvalues i = 1/`max_str' {
				confirm integer number `mat_row_str`i''
				confirm integer number `mat_col_str`i''
				local width_mstr = `width_mstr' + 64 + `mat_length_str`i'' + 16*`mat_row_str`i''*`mat_col_str`i''
			}
		}
	local width "`init_data_size'"
	foreach x of local types {
		local width = `width' + `width_`x''
	}
	local width = `width'/(1024^2)	/* byte2Mbyte */
		if `width' > `total_all_mem' {
		di as error " Insufficient memory to run SCREENING!"
		di as error " You have the following alternatives:"
		di ""
		di as error " 1.  Store your variables more efficiently; see {manhelp compress R}."
		di as error "     (Think of Stata's data area as the area of a rectangle; Stata can trade off width and length.)"
		di ""
		di as error " 2.  Drop some variables or observations; see {manhelp drop R}."
		di ""
		di " 3.  Increase the amount of memory allocated to the data area using the set memory command; see {manhelp memory R}."
		exit 900
	}
	.`memcheck' = ._tab.new, col(2) lmargin(0)
	.`memcheck'.width  20 | 14
	.`memcheck'.titlefmt  %19s  %13s
    .`memcheck'.pad       2  2
    .`memcheck'.numfmt    . %11.2f
	di ""
	.`memcheck'.sep, top
	.`memcheck'.titles "Memory check" "Mbyte"
	.`memcheck'.sep, middle
	.`memcheck'.row  "Required" `width'
	.`memcheck'.row  "Total allocated" `total_all_mem'
	.`memcheck'.sep, bottom

end

*************************************************************************
