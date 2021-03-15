{smcl}
{* *! version 1.0.1  17jan2021}{...}
{viewerjumpto "Syntax" "outdetect##syntax"}{...}
{viewerjumpto "Description" "outdetect##description"}{...}
{viewerjumpto "Options" "outdetect##options"}{...}
{viewerjumpto "Examples" "outdetect##examples"}{...}
{viewerjumpto "Stored results" "outdetect##results"}{...}
{viewerjumpto "Reference" "outdetect##reference"}{...}
{p2colset 1 14 19 2}{...}
{p2col:{bf: outdetect} {hline 2}}Outlier detection and treatment
{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}


{p 8 15 2}
{cmd:outdetect}  {it:{help varname:varname}} [{help if}] [{help in}]
[{it:{help outdetect##weight:weight}}]
	[{cmd:,} {it:{help outdetect##opts:options}}]



{marker opts}{...}
{synoptset 29 tabbed}{...}
{synopthdr:options}
{synoptline}
{syntab:Main}
{synopt :{cmdab:norm:alize(}{it:{help outdetect##normtype:normtype}})}specify the method for normalizing {help varname}{p_end}
{synopt :{cmdab:bestnorm:alize}}specify that the best among the available transformations has to be used for normalizing {help varname}{p_end}
{synopt :{cmdab:zscore(}{it:{help outdetect##stat1:stat1}} {it:{help outdetect##stat2:stat2}})}define the {it:z}-score of the normalized variable{p_end}
{synopt :{opt alpha(#)}}specify the threshold of the outlier detection region; default is 3{p_end}
{synopt :{opt out:liers(bottom|top|both)}}specify whether outliers are to be flagged at the bottom, top, or on both sides of the distribution of {help varname}{p_end}
{synopt :{opt non:egative}}exclude negative values of varname from all calculations{p_end}
{synopt :{opt noz:ero}}exclude zero values of varname from all  calculations{p_end}
{synopt :{opt madf:actor(#)}}specify Fisher consistency factor for median absolute deviation; default is 1.4826022{p_end}
{synopt :{opt sf:actor(#)}}specify Fisher consistency factor for S-statistic; default is 1.1926{p_end}
{synopt :{opt qf:actor(#)}}specify Fisher consistency factor for Q-statistic; default is 2.2219{p_end}
{synopt :{opt nog:enerate}}do not create {it:_out} variable{p_end}
{synopt :{opt replace}}replace existing {it:_out} variable{p_end}
{synopt :{opt rew:eight}}create a new variable containing the post-detection adjusted weights. Only if {help weights} or {help svyset} are used to specify a weight variable{p_end}

{syntab:Reporting}
{synopt :{cmd:pline(# | {help varname})}}specify a poverty line and report poverty estimates{p_end}
{synopt :{opt sformat(%fmt)}}specify format for summary statistics panel{p_end}
{synopt :{opt iformat(%fmt)}}specify format for inequality estimates panel{p_end}
{synopt :{opt se}}report standard errors of statistics{p_end}
{synopt :{opt diff}}test differences between "raw" and "trimmed" statistics{p_end}
{synopt :{cmd:excel({help filename} [, replace])}}export output in Excel{p_end}

{syntab:Graphics}
{synopt :{cmdab:g:raph(}{it:{help outdetect##gtype:gtype}})}produce diagnostic plots{p_end}
{synoptline}
{marker weight}{...}
{p 4 6 2}
{cmd:pweight}s are allowed; see {help weights}.
{p_end}
{p 4 6 2}
{help svyset} can be used to designate variables containing information about the survey design, such as the sampling units and probability weights.
{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:outdetect} identifies and treats extreme values, either "too small" or "too large" observations, in the distribution of {help varname}.

{pstd}
Users may also exploit {help svyset} to specify the survey design of the data before using {cmd:outdetect}.

{pstd}
By default, {cmd:outdetect} creates a new variable, {it:_out}, containing numeric codes that flag outliers of {help varname} (0 for observations that are not outliers, 1 for bottom outliers, 2 for top outliers).

{pstd}
The output of {cmd:outdetect} reports "Raw" statistics (computed using {help varname}), as well as "Trimmed" statistics (computed using just those observations of {help varname} that are not flagged as outliers).

{pstd}
The procedure by which outliers are detected is described in Belotti et
al. (2021), and involves two steps.
First, the distribution of the target
variable ({help varname}) is transformed to approach a standard normal distribution.
To do so, {help varname} is normalized (a transformation is applied so that its distribution approaches a Normal), then standardized (a {it:z}-score of the transformed variable is computed, which may be a "robustified" score, one that uses
robust measures of location and scale rather than the mean and standard deviation).
Second, a threshold is applied to the transformed variable, to set the bounds of an outlier detection region.
The threshold is conventional, and is usually selected to identify the tails of the transformed distribution.

{pstd}
In formulas:

{pstd}
target variable (varname) = v{p_end}
{pstd}
normalized variable 	  = x 	= {it:t}(v){p_end}

{p 2}
where {it:t} is a normalizing transformation
{p_end}

{pstd}
{it:z}-score of x 			  = z 	= (x - {it:stat1})/{it:stat2}{p_end}

{p 2}
where {it:stat1} is a measure of location and {it:stat2} is a measure of scale{p_end}

{pstd}
alpha					  = 	  conventional threshold{p_end}

{pstd}
An observation of {it:v} is flagged as an outlier if:{p_end}
{pstd}
|z| > alpha (both bottom and top outliers), or{p_end}
{pstd}
z > alpha (top outlier), or{p_end}
{pstd}
z < -alpha (bottom outlier).{p_end}



{marker options}{...}
{title:Options}

{dlgtab:Main}

{phang}
{opt normalize(normtype)} specifies the method for transforming varname into a distribution that approaches a Normal distribution. {it:normtype} may be selected among the following transformations:

{marker normtype}{...}
{phang2}
{cmd:normalize(yj)} applies Yeo and Johnson (2000) (default);

{phang2}
{cmd:normalize(asinh)} applies the inverse hyperbolic sine (Friedline et al. 2014).

{phang2}
{cmd:normalize(bcox)} applies the Box-Cox transform (Box and Cox 1964);

{phang2}
{cmd:normalize(ln)} applies the natural logarithm, i.e. ln(x);

{phang2}
{cmd:normalize(log10)} applies {cmd:log10(x + a)} with a = max(0, -(min(x) - 0.0001));

{phang2}
{cmd:normalize(log)} applies {cmd:log(x + a)} with a = max(0, -(min(x) - 0.0001));

{phang2}
{cmd:normalize(sqrt)} applies the square root;

{phang2}
{cmd:normalize(none)} does not apply any transformation (varname used as is).

{phang}
{opt bestnormalize} selects the best transformation according to the value of the Pearson P statistic divided by its degrees of freedom (df). Since this ratio converges to 1 when the data closely follows a Gaussian distribution,
it can be compared between transformations as an absolute measure of the departure from normality. When natural logarithm and inverse hyperbolic sine transformations show the same ratio, the former is selected.
When this option is specified, {cmd:outdetect} stores the Pearson/df ratio corresponding to the best normalizing transformation.

{phang}
{opt zscore(stat1 stat2)} specifies how to define the {it:z}-score of the normalized variable. If {it:x} is the normalized variable, the {it:z}-score is defined as {it: z = (x - stat1)/stat2}.

{marker stat1}{...}
{p 10}
{it:stat1} can be chosen among the following:{p_end}
{p 12}
{it:mean}, mean of {it:x};{p_end}
{p 12}
{it: median}, median of {it:x};{p_end}

{marker stat2}{...}
{p 10}
{it:stat2} can be chosen among the following:{p_end}
{p 12}
{it: std}, standard deviation of {it:x};{p_end}
{p 12}
{it: mad}, median absolute deviation;{p_end}
{p 12}
{it: iqr}, interquartile range;{p_end}
{p 12}
{it: s}, S-statistic (Rousseeuw and Croux, 1993);{p_end}
{p 12}
{it: q}, Q-statistic (Rousseeuw and Croux, 1993);{p_end}

{phang}
{opt alpha(#)} specifies the threshold of the outlier detection region, which is defined with reference to the distribution of the {it:z}-score. The default is 3, but conventional values may range between 2 and 4, depending on  the context.

{phang}
{opt outliers(bottom|top|both)} specifies whether outliers are to be flagged at one or both sides of the distribution of {help varname}.

{p 12}
{it: bottom}, only flags bottom ("too small") outliers;{p_end}
{p 12}
{it: top}, only flags top ("too large") outliers;{p_end}
{p 12}
{it: both}, flags both bottom and top outliers (default).{p_end}

{phang}
{opt nonegative} excludes negative values of {help varname} from the detection routine, the computation of summary statistics, and all other calculations.

{phang}
{opt nozero} excludes zeros of {help varname} from the detection routine, the computation of summary statistics, and all other calculations.

{phang}
{opt madfactor(#)} specifies the Fisher consistency factor to be applied to the median absolute deviation, if this statistic is selected for the calculation of the z-score. The default is 1.4826022.

{phang}
{opt sfactor(#)} specifies the Fisher consistency factor to be applied to the S-statistic, if this statistic is selected for the calculation of the z-score. The default is 1.1926.

{phang}
{opt qfactor(#)} specifies the Fisher consistency factor to be applied to the Q-statistic, if this statistic is selected for the calculation of the z-score. The default is 2.2219.

{phang}
{opt nogenerate} specifies that variable {it:_out} (which flags outliers of {help varname}) not be created.

{phang}
{opt replace} replaces any existing variable named {it:_out} with the new {it:_out} variable created by issuing {cmd:outdetect}.

{phang}
{opt reweight} creates a new variable containing the post-detection adjusted weights. Only if {help weights} or {help svyset} are used to specify a weight variable.


{dlgtab:Reporting}

{phang}
{opt pline(# | varname)} specifies a poverty line, either as a scalar or as a variable. If {cmd:pline()} is specified, the output reports three poverty indices from the Foster, Greer and Thorbecke (1984) class,
namely the poverty headcount (H), poverty gap (PG), and poverty gap squared (PG2).

{phang}
{opt sformat(%fmt)} specifies a format for the summary statistics panel.

{phang}
{opt iformat(%fmt)} specifies a format for the inequality estimates panel.

{phang}
{opt se} reports standard errors of all statistics in the output.

{phang}
{opt diff} reports results of tests of the differences between "raw" and "trimmed" statistics.

{phang}
{opt excel}({it:{help filename}} [, replace]) exports the output table produced by the program in Excel workbook {help filename}. If the {cmd:replace} option is specified, the existing {help filename} is overwritten.

{dlgtab:Graphics}

{phang}
{opt graph}({it:type} [, replace]) produces diagnostic plots where {it:type} can be chosen among the following:

{phang2}
{opt itc}({it:#} [: {help outdetect##itc_options:{it:itc_options}}]) produces the Incremental Trimming Curve (ITC) for a statistic of interest {help outdetect##MV2021:(Mancini and Vecchi, 2021)}.
The ITC reports the value of the statistic of choice, as a function of how many extreme values are discarded (trimmed) from the distribution of {help varname:varname}. By default, the horizontal axis reports the number of trimmed observations as a percentage of all non-missing values of {help varname:varname}, but the number can be reported in absolute terms, too. # indicates the maximum of the horizontal axis.

{phang2}
{cmd:qqplot} plots the quantiles of the {it:z}-score against the quantiles of the standard Normal distribution (Quantile-Quantile plot).


{marker itc_options}{...}
{synoptset 20 tabbed}{...}
{synopthdr: {it: itc_options}}
{synoptline}
{synopt :{opt absolute}}specifies that the horizontal axis report the number of trimmed observations as is, rather than as a percentage of the total number of observations{p_end}
{synopt :{opt gi:ni}}Gini index (default){p_end}
{synopt :{opt m:ean}}sample mean{p_end}
{synopt :{opt h}}poverty headcount rate{p_end}
{synopt :{opt pg}}poverty gap{p_end}
{synopt :{opt pg2}}poverty gap squared{p_end}
{synopt :{cmd:pline({help varname} | #)}}specifies the poverty line. It can be specified only when {it:h}, {it:pg} or {it:pg2} are specified. Default is {cmd:pline(0.60*median({help varname:varname}))}{p_end}
{synoptline}




{marker examples}{...}
{title:Examples}

{pstd}Load demo data:{p_end}
{phang2}
{cmd:. use https://raw.github.com/fbelotti/Stata/master/dta/outdetect, clear}
{p_end}

{pstd}Run {cmd:outdetect} using {help weights}:{p_end}
{phang2}{cmd:. outdetect pce [pweight=weight]}{p_end}

{pstd}Setup using {help svyset}:{p_end}
{phang2}{cmd:. svyset [pweight=weight]}{p_end}
{phang2}{cmd:. outdetect pce}{p_end}

{phang2}
{cmd:. outdetect pce, pline(215000)}
{p_end}
{phang2}
{cmd:. outdetect pce, norm(log)}
{p_end}
{phang2}
{cmd:. outdetect pce, norm(yj) zscore(median s) alpha(2.5)}
{p_end}
{phang2}
{cmd:. outdetect pce, graph(itc(10))}
{p_end}
{phang2}
{cmd:. outdetect pce, graph(itc(10: abs mean))}
{p_end}
{phang2}{cmd:. generate povertyline = 215000}{p_end}
{phang2}{cmd:. outdetect pce, graph(itc(10: pg2 pline(povertyline)))}{p_end}
{phang2}
{cmd:. outdetect pce, graph(qqplot)}
{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:outdetect} stores the following in {cmd:r()}:

{synoptset 17 tabbed}{...}
{p2col 5 15 19 2: Scalars}{p_end}
{synopt:{cmd:r(N_raw)}}number of used observations{p_end}
{synopt:{cmd:r(N_trimmed)}}number of observations after outlier trimming{p_end}
{synopt:{cmd:r(bestnormalize)}}1 if bestnormalize, 0 otherwise{p_end}
{synopt:{cmd:r(pearson_df)}}ratio of the Pearson P statistic and df{p_end}
{synopt:{cmd:r(alpha)}}threshold used for defining the outlier detection region{p_end}



{p2col 5 25 29 2: Macros}{p_end}
{synopt:{cmd:r(normalization)}}applied normalization{p_end}
{synopt:{cmd:r(cmd)}}command name{p_end}

{p2col 5 25 29 2: Matrices}{p_end}
{synopt:{cmd:r(out)}}matrix containing information on the outliers' incidence{p_end}
{synopt:{cmd:r(b)}}matrix containing statistics for the raw and trimmed variable{p_end}



{marker reference}{...}
{title:Reference}

{marker MV2021}{...}
{phang}
Belotti, F., Mancini, G., and Vecchi, G. 2021. Poverty and inequality with dirty data: outlier detection for welfare analysts. Mimeo.
{p_end}

{marker contact}{...}
{title:Contact}
{phang}
To report any problems, please contact Giovanni Vecchi (giovanni.vecchi@uniroma2.it)
{p_end}
