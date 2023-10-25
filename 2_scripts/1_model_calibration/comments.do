
* avoid missing data problems at maximum
	
	*Impute urban and rural
	*Impute gender
	*Be consistent with employed workers
	
	*What happens when you 
	
*Produce a report of consumption labor income shares and check they replicate the stats from Eliza.

*Do we want to use the projections...?

*How does the share behave when comapred to 2018 data 


*-------------------

I do not understand your lines 

gen ebe_factor=1.6
gen mixed_income=self_employee_income* ebe_factor //Define mixed income

gen self_factor=self_employee_income/mixed_income //Define part of self employed income in mixed income