Choosing replications
================
Amy Heather
2026-01-22

- [Set up](#set-up)
- [Choosing the number of
  replications](#choosing-the-number-of-replications)
- [Automated detection of the number of
  replications](#automated-detection-of-the-number-of-replications)
- [Sensitivity analysis: running algorithm with seed
  offset](#sensitivity-analysis-running-algorithm-with-seed-offset)
- [Chosen number of replications](#chosen-number-of-replications)
- [Explanation of the automated
  method](#explanation-of-the-automated-method)
  - [WelfordStats](#welfordstats)
  - [ReplicationTabuliser](#replicationtabuliser)
  - [ReplicationsAlgorithm](#replicationsalgorithm)
- [Run time](#run-time)

This notebook documents the choice of the number of replications.

The generated images are saved and then loaded, so that we view the
image as saved (i.e. with the dimensions set in `ggsave()`). This also
avoids the creation of a `_files/` directory when knitting the document
(which would save all previewed images into that folder also, so they
can be rendered and displayed within the output `.md` file, even if we
had not specifically saved them). These are viewed using
`include_graphics()`, which must be the last command in the cell (or
last in the plotting function).

Some of these figures are used in the paper (`mock_paper.md`) - see
below:

- **Figure C.1:** `outputs/reps_algorithm_wait_time.png`
- **Figure C.2:** `outputs/reps_algorithm_serve_time.png`
- **Figure C.3:** `outputs/reps_algorithm_utilisation.png`

The run time is provided at the end of the notebook.

## Set up

Install the latest version of the local simulation package. If running
sequentially, `devtools::load_all()` is sufficient. If running in
parallel, you must use `devtools::install()` and then
`library(simulation)`.

``` r
devtools::load_all()
```

    ## ℹ Loading simulation

Load required packages.

``` r
# nolint start: undesirable_function_linter.
library(data.table)
library(dplyr)
```

    ## 
    ## Attaching package: 'dplyr'

    ## The following objects are masked from 'package:data.table':
    ## 
    ##     between, first, last

    ## The following object is masked from 'package:testthat':
    ## 
    ##     matches

    ## The following objects are masked from 'package:stats':
    ## 
    ##     filter, lag

    ## The following objects are masked from 'package:base':
    ## 
    ##     intersect, setdiff, setequal, union

``` r
library(knitr)

options(data.table.summarise.inform = FALSE)
options(dplyr.summarise.inform = FALSE)
# nolint end
```

Start timer.

``` r
start_time <- Sys.time()
```

Define path to outputs folder.

``` r
output_dir <- file.path("..", "outputs")
```

## Choosing the number of replications

The **confidence interval method** can help you decide how many
replications (runs) your simulation needs. The more replications you
run, the narrower your confidence interval becomes, leading to a more
precise estimate of the model’s mean performance.

There are two main calculations:

- **Confidence interval**. This is the range where the true mean is
  likely to be, based on your simulation results. For example, a 95%
  confidence interval means that, if you repeated the experiment many
  times, about 95 out of 100 intervals would contain the true mean.
- **Precision**. This tells you how close that range is to your mean.
  For example, if your mean is 50 and your 95% confidence interval is 45
  to 55, your precision is ±10% (because 5 is 10% of 50).

To run this method you:

- Run the model with more and more replications.
- Check after each how wide your confidence interval is.
- Stop when the interval is narrow enough to meet your desired
  precision.
- Make sure the interval stays this narrow if you keep running more
  replications.

This method is less useful for values very close to zero - so, for
example, when using utilisation (which ranges from 0 to 1) it is
recommended to multiple values by 100.

When deciding how many replications you need, repeat this process for
each performance measure you care about, and use the largest number you
find.

It’s important to check ahead, to check that the 10% precision is
maintained - which is fine in this case - it doesn’t go back up to
future deviation.

It’s important to run this check on multiple metrics.

``` r
metrics <- c(
  "mean_waiting_time_nurse",
  "utilisation_nurse",
  "mean_queue_length_nurse",
  "mean_time_in_system",
  "mean_patients_in_service"
)

ci_list <- list()
for (m in metrics) {
  ci_list[[m]] <- confidence_interval_method(
    replications = 20L,
    desired_precision = 0.1,
    metric = m
  )
}
```

    ## $patient_inter
    ## [1] 4
    ## 
    ## $mean_n_consult_time
    ## [1] 10
    ## 
    ## $number_of_nurses
    ## [1] 5
    ## 
    ## $warm_up_period
    ## [1] 10080
    ## 
    ## $data_collection_period
    ## [1] 20160
    ## 
    ## $number_of_runs
    ## [1] 20
    ## 
    ## $scenario_name
    ## NULL
    ## 
    ## $cores
    ## [1] 1
    ## 
    ## $seed_offset
    ## [1] 0
    ## 
    ## $log_to_console
    ## [1] FALSE
    ## 
    ## $log_to_file
    ## [1] FALSE
    ## 
    ## $file_path
    ## NULL

    ## Reached desired precision (0.1) in 4 replications.

    ## $patient_inter
    ## [1] 4
    ## 
    ## $mean_n_consult_time
    ## [1] 10
    ## 
    ## $number_of_nurses
    ## [1] 5
    ## 
    ## $warm_up_period
    ## [1] 10080
    ## 
    ## $data_collection_period
    ## [1] 20160
    ## 
    ## $number_of_runs
    ## [1] 20
    ## 
    ## $scenario_name
    ## NULL
    ## 
    ## $cores
    ## [1] 1
    ## 
    ## $seed_offset
    ## [1] 0
    ## 
    ## $log_to_console
    ## [1] FALSE
    ## 
    ## $log_to_file
    ## [1] FALSE
    ## 
    ## $file_path
    ## NULL

    ## Reached desired precision (0.1) in 3 replications.

    ## $patient_inter
    ## [1] 4
    ## 
    ## $mean_n_consult_time
    ## [1] 10
    ## 
    ## $number_of_nurses
    ## [1] 5
    ## 
    ## $warm_up_period
    ## [1] 10080
    ## 
    ## $data_collection_period
    ## [1] 20160
    ## 
    ## $number_of_runs
    ## [1] 20
    ## 
    ## $scenario_name
    ## NULL
    ## 
    ## $cores
    ## [1] 1
    ## 
    ## $seed_offset
    ## [1] 0
    ## 
    ## $log_to_console
    ## [1] FALSE
    ## 
    ## $log_to_file
    ## [1] FALSE
    ## 
    ## $file_path
    ## NULL

    ## Reached desired precision (0.1) in 4 replications.

    ## $patient_inter
    ## [1] 4
    ## 
    ## $mean_n_consult_time
    ## [1] 10
    ## 
    ## $number_of_nurses
    ## [1] 5
    ## 
    ## $warm_up_period
    ## [1] 10080
    ## 
    ## $data_collection_period
    ## [1] 20160
    ## 
    ## $number_of_runs
    ## [1] 20
    ## 
    ## $scenario_name
    ## NULL
    ## 
    ## $cores
    ## [1] 1
    ## 
    ## $seed_offset
    ## [1] 0
    ## 
    ## $log_to_console
    ## [1] FALSE
    ## 
    ## $log_to_file
    ## [1] FALSE
    ## 
    ## $file_path
    ## NULL

    ## Reached desired precision (0.1) in 3 replications.

    ## $patient_inter
    ## [1] 4
    ## 
    ## $mean_n_consult_time
    ## [1] 10
    ## 
    ## $number_of_nurses
    ## [1] 5
    ## 
    ## $warm_up_period
    ## [1] 10080
    ## 
    ## $data_collection_period
    ## [1] 20160
    ## 
    ## $number_of_runs
    ## [1] 20
    ## 
    ## $scenario_name
    ## NULL
    ## 
    ## $cores
    ## [1] 1
    ## 
    ## $seed_offset
    ## [1] 0
    ## 
    ## $log_to_console
    ## [1] FALSE
    ## 
    ## $log_to_file
    ## [1] FALSE
    ## 
    ## $file_path
    ## NULL

    ## Reached desired precision (0.1) in 3 replications.

``` r
metric_titles <- c(
  mean_waiting_time_nurse = "Mean wait time for the nurse",
  utilisation_nurse       = "Mean nurse utilisation",
  mean_queue_length_nurse = "Mean queue length for nurse",
  mean_time_in_system     = "Mean time in system",
  mean_patients_in_service = "Mean patients in service"
)

metric_min_rep <- c(
  mean_waiting_time_nurse = 4L,
  utilisation_nurse = 3L,
  mean_queue_length_nurse = 4L,
  mean_time_in_system = 3L,
  mean_patients_in_service = 3L
)

for (m in metrics) {
  path <- file.path(output_dir, paste0("conf_int_method_", m, ".png"))
  plot_replication_ci(
    conf_ints   = ci_list[[m]],
    yaxis_title = metric_titles[[m]],
    file_path   = path,
    min_rep     = metric_min_rep[[m]]
  )
  include_graphics(path)
}
```

## Automated detection of the number of replications

Run the algorithm (which will run model with increasing reps) for a few
different metrics.

``` r
# Set up and run algorithm
alg <- ReplicationsAlgorithm$new(param = parameters(), metrics = metrics)
```

    ## [1] "Model parameters:"
    ## $patient_inter
    ## [1] 4
    ## 
    ## $mean_n_consult_time
    ## [1] 10
    ## 
    ## $number_of_nurses
    ## [1] 5
    ## 
    ## $warm_up_period
    ## [1] 10080
    ## 
    ## $data_collection_period
    ## [1] 20160
    ## 
    ## $number_of_runs
    ## [1] 25
    ## 
    ## $scenario_name
    ## NULL
    ## 
    ## $cores
    ## [1] 1
    ## 
    ## $seed_offset
    ## [1] 0
    ## 
    ## $log_to_console
    ## [1] FALSE
    ## 
    ## $log_to_file
    ## [1] FALSE
    ## 
    ## $file_path
    ## NULL

``` r
alg$select()
```

``` r
# View results
alg$nreps
```

    ## $mean_waiting_time_nurse
    ## [1] 19
    ## 
    ## $utilisation_nurse
    ## [1] 3
    ## 
    ## $mean_queue_length_nurse
    ## [1] 19
    ## 
    ## $mean_time_in_system
    ## [1] 3
    ## 
    ## $mean_patients_in_service
    ## [1] 3

``` r
alg$summary_table
```

    ##    replications        data cumulative_mean       stdev    lower_ci   upper_ci
    ## 1             1  0.46719622       0.4671962          NA          NA         NA
    ## 2             2  0.46710137       0.4671488          NA          NA         NA
    ## 3             3  0.50741855       0.4805720 0.023249804  0.42281633  0.5383278
    ## 4             4  0.48106967       0.4806965 0.018985016  0.45048705  0.5109058
    ## 5             5  0.39347099       0.4632514 0.042331778  0.41068951  0.5158132
    ## 6             6  0.44198792       0.4597075 0.038845066  0.41894205  0.5004728
    ## 7             7  0.72994244       0.4983125 0.108119707  0.39831840  0.5983065
    ## 8             8  0.66648579       0.5193341 0.116426687  0.42199897  0.6166693
    ## 9             9  0.58525183       0.5266583 0.111101623  0.44125804  0.6120586
    ## 10           10  0.42820922       0.5168134 0.109276187  0.43864192  0.5949849
    ## 11           11  0.49584073       0.5149068 0.103861173  0.44513191  0.5846817
    ## 12           12  0.69406027       0.5298362 0.111719103  0.45885332  0.6008192
    ## 13           13  0.40617510       0.5203239 0.112327091  0.45244527  0.5882024
    ## 14           14  0.46630222       0.5164652 0.108881866  0.45359865  0.5793317
    ## 15           15  0.38076184       0.5074183 0.110617129  0.44616055  0.5686760
    ## 16           16  0.44092445       0.5032624 0.108151492  0.44563255  0.5608923
    ## 17           17  0.50179976       0.5031764 0.104717833  0.44933543  0.5570173
    ## 18           18  0.50497855       0.5032765 0.101592108  0.45275593  0.5537971
    ## 19           19  0.54830791       0.5056466 0.099268816  0.45780053  0.5534926
    ## 20           20  0.47752984       0.5042407 0.096825503  0.45892500  0.5495565
    ## 21           21  0.58073135       0.5078831 0.095838559  0.46425795  0.5515083
    ## 22           22  0.37927898       0.5020375 0.097464974  0.45882395  0.5452510
    ## 23           23  0.41704715       0.4983423 0.096859116  0.45645724  0.5402273
    ## 24           24  0.56142409       0.5009707 0.095601223  0.46060182  0.5413395
    ## 25            1  0.49198233       0.4919823          NA          NA         NA
    ## 26            2  0.50922907       0.5006057          NA          NA         NA
    ## 27            3  0.49071287       0.4973081 0.010343360  0.47161376  0.5230024
    ## 28            4  0.51001866       0.5004857 0.010569440  0.48366740  0.5173041
    ## 29            5  0.50050433       0.5004895 0.009153408  0.48912400  0.5118549
    ## 30            6  0.49957510       0.5003371 0.008195562  0.49173635  0.5089378
    ## 31            7  0.50667105       0.5012419 0.007855192  0.49397708  0.5085068
    ## 32            8  0.51414502       0.5028548 0.008584897  0.49567765  0.5100320
    ## 33            1  0.11429987       0.1142999          NA          NA         NA
    ## 34            2  0.12235253       0.1183262          NA          NA         NA
    ## 35            3  0.13162348       0.1227586 0.008668943  0.10122378  0.1442935
    ## 36            4  0.11738750       0.1214158 0.007570512  0.10936947  0.1334622
    ## 37            5  0.09632996       0.1163987 0.012994031  0.10026445  0.1325329
    ## 38            6  0.10673041       0.1147873 0.012274163  0.10190635  0.1276682
    ## 39            7  0.17830179       0.1238608 0.026492353  0.09935945  0.1483621
    ## 40            8  0.17319818       0.1300280 0.030097400  0.10486591  0.1551900
    ## 41            9  0.14495701       0.1316867 0.028589961  0.10971056  0.1536629
    ## 42           10  0.10329149       0.1288472 0.028411165  0.10852310  0.1491713
    ## 43           11  0.12879269       0.1288423 0.026953202  0.11073486  0.1469497
    ## 44           12  0.17096162       0.1323522 0.028430066  0.11428861  0.1504158
    ## 45           13  0.09600230       0.1295561 0.029026757  0.11201537  0.1470968
    ## 46           14  0.11760165       0.1287022 0.028070422  0.11249480  0.1449096
    ## 47           15  0.09231269       0.1262762 0.028634702  0.11041884  0.1421336
    ## 48           16  0.10731302       0.1250910 0.028067032  0.11013515  0.1400469
    ## 49           17  0.13403774       0.1256173 0.027262279  0.11160032  0.1396343
    ## 50           18  0.12624987       0.1256524 0.026448716  0.11249980  0.1388051
    ## 51           19  0.12916518       0.1258373 0.025716162  0.11344252  0.1382321
    ## 52           20  0.12916639       0.1260038 0.025041341  0.11428406  0.1377235
    ## 53           21  0.14511982       0.1269141 0.024761188  0.11564290  0.1381852
    ## 54           22  0.08884140       0.1251835 0.025491332  0.11388126  0.1364857
    ## 55           23  0.10206847       0.1241785 0.025367339  0.11320882  0.1351481
    ## 56           24  0.13803897       0.1247560 0.024970547  0.11421186  0.1353001
    ## 57            1 10.30566681      10.3056668          NA          NA         NA
    ## 58            2 10.61031372      10.4579903          NA          NA         NA
    ## 59            3 10.38530420      10.4337616 0.157998492 10.04127157 10.8262516
    ## 60            4 10.67441682      10.4939254 0.176411694 10.21321502 10.7746358
    ## 61            5 10.46550938      10.4882422 0.153304626 10.29788935 10.6785950
    ## 62            6 10.29094937      10.4553601 0.159025959 10.28847254 10.6222476
    ## 63            7 10.72268192      10.4935489 0.176870267 10.32997118 10.6571266
    ## 64            8 10.77205784      10.5283625 0.191075855 10.36861910 10.6881059
    ## 65            1  2.57690727       2.5769073          NA          NA         NA
    ## 66            2  2.66251947       2.6197134          NA          NA         NA
    ## 67            3  2.57859431       2.6060070 0.048948488  2.48441223  2.7276018
    ## 68            4  2.67101321       2.6222586 0.051514604  2.54028734  2.7042298
    ## 69            5  2.60015065       2.6178370 0.045695381  2.56109867  2.6745753
    ## 70            6  2.60995563       2.6165234 0.040997645  2.57349903  2.6595478
    ## 71            7  2.71573745       2.6306969 0.052979955  2.58169857  2.6796951
    ## 72            8  2.73927599       2.6442692 0.062286210  2.59219667  2.6963418
    ##     deviation                   metric
    ## 1          NA  mean_waiting_time_nurse
    ## 2          NA  mean_waiting_time_nurse
    ## 3  0.12018118  mean_waiting_time_nurse
    ## 4  0.06284506  mean_waiting_time_nurse
    ## 5  0.11346290  mean_waiting_time_nurse
    ## 6  0.08867682  mean_waiting_time_nurse
    ## 7  0.20066537  mean_waiting_time_nurse
    ## 8  0.18742298  mean_waiting_time_nurse
    ## 9  0.16215498  mean_waiting_time_nurse
    ## 10 0.15125667  mean_waiting_time_nurse
    ## 11 0.13550974  mean_waiting_time_nurse
    ## 12 0.13397145  mean_waiting_time_nurse
    ## 13 0.13045449  mean_waiting_time_nurse
    ## 14 0.12172460  mean_waiting_time_nurse
    ## 15 0.12072432  mean_waiting_time_nurse
    ## 16 0.11451255  mean_waiting_time_nurse
    ## 17 0.10700213  mean_waiting_time_nurse
    ## 18 0.10038332  mean_waiting_time_nurse
    ## 19 0.09462348  mean_waiting_time_nurse
    ## 20 0.08986924  mean_waiting_time_nurse
    ## 21 0.08589611  mean_waiting_time_nurse
    ## 22 0.08607634  mean_waiting_time_nurse
    ## 23 0.08404871  mean_waiting_time_nurse
    ## 24 0.08058128  mean_waiting_time_nurse
    ## 25         NA        utilisation_nurse
    ## 26         NA        utilisation_nurse
    ## 27 0.05166683        utilisation_nurse
    ## 28 0.03360403        utilisation_nurse
    ## 29 0.02270868        utilisation_nurse
    ## 30 0.01718984        utilisation_nurse
    ## 31 0.01449368        utilisation_nurse
    ## 32 0.01427281        utilisation_nurse
    ## 33         NA  mean_queue_length_nurse
    ## 34         NA  mean_queue_length_nurse
    ## 35 0.17542432  mean_queue_length_nurse
    ## 36 0.09921583  mean_queue_length_nurse
    ## 37 0.13861173  mean_queue_length_nurse
    ## 38 0.11221577  mean_queue_length_nurse
    ## 39 0.19781353  mean_queue_length_nurse
    ## 40 0.19351265  mean_queue_length_nurse
    ## 41 0.16688232  mean_queue_length_nurse
    ## 42 0.15773815  mean_queue_length_nurse
    ## 43 0.14053935  mean_queue_length_nurse
    ## 44 0.13648130  mean_queue_length_nurse
    ## 45 0.13539076  mean_queue_length_nurse
    ## 46 0.12592933  mean_queue_length_nurse
    ## 47 0.12557686  mean_queue_length_nurse
    ## 48 0.11955987  mean_queue_length_nurse
    ## 49 0.11158472  mean_queue_length_nurse
    ## 50 0.10467475  mean_queue_length_nurse
    ## 51 0.09849855  mean_queue_length_nurse
    ## 52 0.09301078  mean_queue_length_nurse
    ## 53 0.08880937  mean_queue_length_nurse
    ## 54 0.09028526  mean_queue_length_nurse
    ## 55 0.08833785  mean_queue_length_nurse
    ## 56 0.08451808  mean_queue_length_nurse
    ## 57         NA      mean_time_in_system
    ## 58         NA      mean_time_in_system
    ## 59 0.03761731      mean_time_in_system
    ## 60 0.02674980      mean_time_in_system
    ## 61 0.01814916      mean_time_in_system
    ## 62 0.01596191      mean_time_in_system
    ## 63 0.01558841      mean_time_in_system
    ## 64 0.01517267      mean_time_in_system
    ## 65         NA mean_patients_in_service
    ## 66         NA mean_patients_in_service
    ## 67 0.04665942 mean_patients_in_service
    ## 68 0.03125978 mean_patients_in_service
    ## 69 0.02167374 mean_patients_in_service
    ## 70 0.01644334 mean_patients_in_service
    ## 71 0.01862559 mean_patients_in_service
    ## 72 0.01969261 mean_patients_in_service

Visualise results for each metric…

``` r
for (m in metrics) {
  path <- file.path(output_dir, paste0("reps_algorithm_", m, ".png"))
  plot_replication_ci(
    conf_ints = dplyr::filter(alg$summary_table, metric == m),
    yaxis_title = metric_titles[[m]],
    file_path = path,
    min_rep = alg$nreps[[m]]
  )
  include_graphics(path)
}
```

## Sensitivity analysis: running algorithm with seed offset

To check the stability of the suggested number of replications, run
again with a new set of seeds using `seed_offset`.

``` r
# Set up and run algorithm
alg <- ReplicationsAlgorithm$new(
  param   = parameters(seed_offset = 1000L),
  metrics = metrics
)
```

    ## [1] "Model parameters:"
    ## $patient_inter
    ## [1] 4
    ## 
    ## $mean_n_consult_time
    ## [1] 10
    ## 
    ## $number_of_nurses
    ## [1] 5
    ## 
    ## $warm_up_period
    ## [1] 10080
    ## 
    ## $data_collection_period
    ## [1] 20160
    ## 
    ## $number_of_runs
    ## [1] 25
    ## 
    ## $scenario_name
    ## NULL
    ## 
    ## $cores
    ## [1] 1
    ## 
    ## $seed_offset
    ## [1] 1000
    ## 
    ## $log_to_console
    ## [1] FALSE
    ## 
    ## $log_to_file
    ## [1] FALSE
    ## 
    ## $file_path
    ## NULL

``` r
alg$select()

# View results
alg$nreps
```

    ## $mean_waiting_time_nurse
    ## [1] 10
    ## 
    ## $utilisation_nurse
    ## [1] 3
    ## 
    ## $mean_queue_length_nurse
    ## [1] 12
    ## 
    ## $mean_time_in_system
    ## [1] 3
    ## 
    ## $mean_patients_in_service
    ## [1] 3

``` r
alg$summary_table
```

    ##    replications        data cumulative_mean       stdev   lower_ci   upper_ci
    ## 1             1  0.51178779       0.5117878          NA         NA         NA
    ## 2             2  0.46147422       0.4866310          NA         NA         NA
    ## 3             3  0.47575572       0.4830059 0.025928515  0.4185959  0.5474159
    ## 4             4  0.57278348       0.5054503 0.049630584  0.4264770  0.5844236
    ## 5             5  0.45103813       0.4945679 0.049391629  0.4332401  0.5558957
    ## 6             6  0.53907005       0.5019849 0.047767148  0.4518564  0.5521134
    ## 7             7  0.35701148       0.4812744 0.070027762  0.4165095  0.5460393
    ## 8             8  0.45192116       0.4776053 0.065658463  0.4227134  0.5324971
    ## 9             9  0.53178495       0.4836252 0.064018079  0.4344166  0.5328339
    ## 10           10  0.54071146       0.4893338 0.062998651  0.4442673  0.5344004
    ## 11           11  0.63650093       0.5027127 0.074437020  0.4527052  0.5527201
    ## 12           12  0.50307612       0.5027430 0.070972991  0.4576489  0.5478370
    ## 13           13  0.46368002       0.4997381 0.068809735  0.4581568  0.5413194
    ## 14           14  0.66893473       0.5118236 0.080096110  0.4655775  0.5580697
    ## 15           15  0.65529481       0.5213883 0.085611980  0.4739780  0.5687987
    ## 16            1  0.49615280       0.4961528          NA         NA         NA
    ## 17            2  0.50444608       0.5002994          NA         NA         NA
    ## 18            3  0.49906880       0.4998892 0.004207070  0.4894383  0.5103402
    ## 19            4  0.50015369       0.4999553 0.003437602  0.4944853  0.5054253
    ## 20            5  0.50555045       0.5010744 0.003888943  0.4962456  0.5059031
    ## 21            6  0.49394848       0.4998867 0.004534549  0.4951280  0.5046454
    ## 22            7  0.47752269       0.4966919 0.009411965  0.4879872  0.5053965
    ## 23            8  0.50868753       0.4981913 0.009691083  0.4900894  0.5062933
    ## 24            1  0.12112547       0.1211255          NA         NA         NA
    ## 25            2  0.12630554       0.1237155          NA         NA         NA
    ## 26            3  0.11846320       0.1219647 0.003987965  0.1120581  0.1318714
    ## 27            4  0.14291582       0.1272025 0.010969938  0.1097469  0.1446581
    ## 28            5  0.10491788       0.1227456 0.013768644  0.1056496  0.1398416
    ## 29            6  0.13596688       0.1249491 0.013445975  0.1108384  0.1390598
    ## 30            7  0.08404104       0.1191051 0.019741562  0.1008472  0.1373630
    ## 31            8  0.12641743       0.1200192 0.018459074  0.1045870  0.1354513
    ## 32            9  0.13626049       0.1218238 0.018095697  0.1079142  0.1357333
    ## 33           10  0.12532766       0.1221741 0.017096730  0.1099439  0.1344044
    ## 34           11  0.16330214       0.1259131 0.020416713  0.1121969  0.1396292
    ## 35           12  0.12806336       0.1260922 0.019476466  0.1137175  0.1384670
    ## 36           13  0.11908007       0.1255528 0.018748441  0.1142233  0.1368824
    ## 37           14  0.17125807       0.1288175 0.021764127  0.1162513  0.1413837
    ## 38           15  0.17164649       0.1316728 0.023709308  0.1185430  0.1448025
    ## 39           16  0.15146860       0.1329100 0.023433908  0.1204230  0.1453971
    ## 40           17  0.12264241       0.1323060 0.022826031  0.1205700  0.1440421
    ## 41            1 10.53726627      10.5372663          NA         NA         NA
    ## 42            2 10.46355316      10.5004097          NA         NA         NA
    ## 43            3 10.47119398      10.4906711 0.040533017 10.3899815 10.5913607
    ## 44            4 10.61582295      10.5219591 0.070788614 10.4093186 10.6345996
    ## 45            5 10.75659390      10.5688861 0.121527649 10.4179895 10.7197826
    ## 46            6 10.44640017      10.5484717 0.119647987 10.4229089 10.6740346
    ## 47            7 10.22845863      10.5027556 0.162970765 10.3520328 10.6534784
    ## 48            8 10.42078226      10.4925089 0.153639882 10.3640628 10.6209551
    ## 49            1  2.60716413       2.6071641          NA         NA         NA
    ## 50            2  2.63751243       2.6223383          NA         NA         NA
    ## 51            3  2.61191276       2.6188631 0.016324381  2.5783111  2.6594151
    ## 52            4  2.64187364       2.6246157 0.017607614  2.5965981  2.6526334
    ## 53            5  2.63826293       2.6273452 0.016424684  2.6069512  2.6477391
    ## 54            6  2.60219023       2.6231527 0.017924232  2.6043424  2.6419630
    ## 55            7  2.47363011       2.6017923 0.058835270  2.5473788  2.6562059
    ## 56            8  2.65835409       2.6088625 0.058025689  2.5603518  2.6573732
    ##      deviation                   metric
    ## 1           NA  mean_waiting_time_nurse
    ## 2           NA  mean_waiting_time_nurse
    ## 3  0.133352408  mean_waiting_time_nurse
    ## 4  0.156243521  mean_waiting_time_nurse
    ## 5  0.124002814  mean_waiting_time_nurse
    ## 6  0.099860669  mean_waiting_time_nurse
    ## 7  0.134569544  mean_waiting_time_nurse
    ## 8  0.114931418  mean_waiting_time_nurse
    ## 9  0.101749557  mean_waiting_time_nurse
    ## 10 0.092097697  mean_waiting_time_nurse
    ## 11 0.099475254  mean_waiting_time_nurse
    ## 12 0.089696109  mean_waiting_time_nurse
    ## 13 0.083206194  mean_waiting_time_nurse
    ## 14 0.090355580  mean_waiting_time_nurse
    ## 15 0.090930945  mean_waiting_time_nurse
    ## 16          NA        utilisation_nurse
    ## 17          NA        utilisation_nurse
    ## 18 0.020906514        utilisation_nurse
    ## 19 0.010940962        utilisation_nurse
    ## 20 0.009636815        utilisation_nurse
    ## 21 0.009519592        utilisation_nurse
    ## 22 0.017525183        utilisation_nurse
    ## 23 0.016262725        utilisation_nurse
    ## 24          NA  mean_queue_length_nurse
    ## 25          NA  mean_queue_length_nurse
    ## 26 0.081225570  mean_queue_length_nurse
    ## 27 0.137227010  mean_queue_length_nurse
    ## 28 0.139280206  mean_queue_length_nurse
    ## 29 0.112931441  mean_queue_length_nurse
    ## 30 0.153292318  mean_queue_length_nurse
    ## 31 0.128580904  mean_queue_length_nurse
    ## 32 0.114177929  mean_queue_length_nurse
    ## 33 0.100105173  mean_queue_length_nurse
    ## 34 0.108933381  mean_queue_length_nurse
    ## 35 0.098140505  mean_queue_length_nurse
    ## 36 0.090237457  mean_queue_length_nurse
    ## 37 0.097550663  mean_queue_length_nurse
    ## 38 0.099715205  mean_queue_length_nurse
    ## 39 0.093951150  mean_queue_length_nurse
    ## 40 0.088703907  mean_queue_length_nurse
    ## 41          NA      mean_time_in_system
    ## 42          NA      mean_time_in_system
    ## 43 0.009598013      mean_time_in_system
    ## 44 0.010705276      mean_time_in_system
    ## 45 0.014277428      mean_time_in_system
    ## 46 0.011903417      mean_time_in_system
    ## 47 0.014350788      mean_time_in_system
    ## 48 0.012241701      mean_time_in_system
    ## 49          NA mean_patients_in_service
    ## 50          NA mean_patients_in_service
    ## 51 0.015484586 mean_patients_in_service
    ## 52 0.010674951 mean_patients_in_service
    ## 53 0.007762185 mean_patients_in_service
    ## 54 0.007170886 mean_patients_in_service
    ## 55 0.020913871 mean_patients_in_service
    ## 56 0.018594575 mean_patients_in_service

``` r
for (m in metrics) {
  path <- file.path(output_dir, paste0("reps_algorithm_", m, "_2.png"))
  plot_replication_ci(
    conf_ints   = dplyr::filter(alg$summary_table, metric == m),
    yaxis_title = metric_titles[[m]],
    file_path   = path,
    min_rep     = alg$nreps[[m]]
  )
  include_graphics(path)
}
```

Further variations, just reporting number of replications:

``` r
seed_offsets <- seq(2000L, 10000L, by = 1000L)
sensitivity_nreps <- list()
for (offset in seed_offsets) {
  alg <- ReplicationsAlgorithm$new(
    param = parameters(seed_offset = offset),
    metrics = metrics
  )
  alg$select()
  sensitivity_nreps <- c(sensitivity_nreps, alg$nreps)
}
```

    ## [1] "Model parameters:"
    ## $patient_inter
    ## [1] 4
    ## 
    ## $mean_n_consult_time
    ## [1] 10
    ## 
    ## $number_of_nurses
    ## [1] 5
    ## 
    ## $warm_up_period
    ## [1] 10080
    ## 
    ## $data_collection_period
    ## [1] 20160
    ## 
    ## $number_of_runs
    ## [1] 25
    ## 
    ## $scenario_name
    ## NULL
    ## 
    ## $cores
    ## [1] 1
    ## 
    ## $seed_offset
    ## [1] 2000
    ## 
    ## $log_to_console
    ## [1] FALSE
    ## 
    ## $log_to_file
    ## [1] FALSE
    ## 
    ## $file_path
    ## NULL
    ## 
    ## [1] "Model parameters:"
    ## $patient_inter
    ## [1] 4
    ## 
    ## $mean_n_consult_time
    ## [1] 10
    ## 
    ## $number_of_nurses
    ## [1] 5
    ## 
    ## $warm_up_period
    ## [1] 10080
    ## 
    ## $data_collection_period
    ## [1] 20160
    ## 
    ## $number_of_runs
    ## [1] 25
    ## 
    ## $scenario_name
    ## NULL
    ## 
    ## $cores
    ## [1] 1
    ## 
    ## $seed_offset
    ## [1] 3000
    ## 
    ## $log_to_console
    ## [1] FALSE
    ## 
    ## $log_to_file
    ## [1] FALSE
    ## 
    ## $file_path
    ## NULL
    ## 
    ## [1] "Model parameters:"
    ## $patient_inter
    ## [1] 4
    ## 
    ## $mean_n_consult_time
    ## [1] 10
    ## 
    ## $number_of_nurses
    ## [1] 5
    ## 
    ## $warm_up_period
    ## [1] 10080
    ## 
    ## $data_collection_period
    ## [1] 20160
    ## 
    ## $number_of_runs
    ## [1] 25
    ## 
    ## $scenario_name
    ## NULL
    ## 
    ## $cores
    ## [1] 1
    ## 
    ## $seed_offset
    ## [1] 4000
    ## 
    ## $log_to_console
    ## [1] FALSE
    ## 
    ## $log_to_file
    ## [1] FALSE
    ## 
    ## $file_path
    ## NULL
    ## 
    ## [1] "Model parameters:"
    ## $patient_inter
    ## [1] 4
    ## 
    ## $mean_n_consult_time
    ## [1] 10
    ## 
    ## $number_of_nurses
    ## [1] 5
    ## 
    ## $warm_up_period
    ## [1] 10080
    ## 
    ## $data_collection_period
    ## [1] 20160
    ## 
    ## $number_of_runs
    ## [1] 25
    ## 
    ## $scenario_name
    ## NULL
    ## 
    ## $cores
    ## [1] 1
    ## 
    ## $seed_offset
    ## [1] 5000
    ## 
    ## $log_to_console
    ## [1] FALSE
    ## 
    ## $log_to_file
    ## [1] FALSE
    ## 
    ## $file_path
    ## NULL
    ## 
    ## [1] "Model parameters:"
    ## $patient_inter
    ## [1] 4
    ## 
    ## $mean_n_consult_time
    ## [1] 10
    ## 
    ## $number_of_nurses
    ## [1] 5
    ## 
    ## $warm_up_period
    ## [1] 10080
    ## 
    ## $data_collection_period
    ## [1] 20160
    ## 
    ## $number_of_runs
    ## [1] 25
    ## 
    ## $scenario_name
    ## NULL
    ## 
    ## $cores
    ## [1] 1
    ## 
    ## $seed_offset
    ## [1] 6000
    ## 
    ## $log_to_console
    ## [1] FALSE
    ## 
    ## $log_to_file
    ## [1] FALSE
    ## 
    ## $file_path
    ## NULL
    ## 
    ## [1] "Model parameters:"
    ## $patient_inter
    ## [1] 4
    ## 
    ## $mean_n_consult_time
    ## [1] 10
    ## 
    ## $number_of_nurses
    ## [1] 5
    ## 
    ## $warm_up_period
    ## [1] 10080
    ## 
    ## $data_collection_period
    ## [1] 20160
    ## 
    ## $number_of_runs
    ## [1] 25
    ## 
    ## $scenario_name
    ## NULL
    ## 
    ## $cores
    ## [1] 1
    ## 
    ## $seed_offset
    ## [1] 7000
    ## 
    ## $log_to_console
    ## [1] FALSE
    ## 
    ## $log_to_file
    ## [1] FALSE
    ## 
    ## $file_path
    ## NULL
    ## 
    ## [1] "Model parameters:"
    ## $patient_inter
    ## [1] 4
    ## 
    ## $mean_n_consult_time
    ## [1] 10
    ## 
    ## $number_of_nurses
    ## [1] 5
    ## 
    ## $warm_up_period
    ## [1] 10080
    ## 
    ## $data_collection_period
    ## [1] 20160
    ## 
    ## $number_of_runs
    ## [1] 25
    ## 
    ## $scenario_name
    ## NULL
    ## 
    ## $cores
    ## [1] 1
    ## 
    ## $seed_offset
    ## [1] 8000
    ## 
    ## $log_to_console
    ## [1] FALSE
    ## 
    ## $log_to_file
    ## [1] FALSE
    ## 
    ## $file_path
    ## NULL
    ## 
    ## [1] "Model parameters:"
    ## $patient_inter
    ## [1] 4
    ## 
    ## $mean_n_consult_time
    ## [1] 10
    ## 
    ## $number_of_nurses
    ## [1] 5
    ## 
    ## $warm_up_period
    ## [1] 10080
    ## 
    ## $data_collection_period
    ## [1] 20160
    ## 
    ## $number_of_runs
    ## [1] 25
    ## 
    ## $scenario_name
    ## NULL
    ## 
    ## $cores
    ## [1] 1
    ## 
    ## $seed_offset
    ## [1] 9000
    ## 
    ## $log_to_console
    ## [1] FALSE
    ## 
    ## $log_to_file
    ## [1] FALSE
    ## 
    ## $file_path
    ## NULL
    ## 
    ## [1] "Model parameters:"
    ## $patient_inter
    ## [1] 4
    ## 
    ## $mean_n_consult_time
    ## [1] 10
    ## 
    ## $number_of_nurses
    ## [1] 5
    ## 
    ## $warm_up_period
    ## [1] 10080
    ## 
    ## $data_collection_period
    ## [1] 20160
    ## 
    ## $number_of_runs
    ## [1] 25
    ## 
    ## $scenario_name
    ## NULL
    ## 
    ## $cores
    ## [1] 1
    ## 
    ## $seed_offset
    ## [1] 10000
    ## 
    ## $log_to_console
    ## [1] FALSE
    ## 
    ## $log_to_file
    ## [1] FALSE
    ## 
    ## $file_path
    ## NULL

``` r
print(sensitivity_nreps)
```

    ## $mean_waiting_time_nurse
    ## [1] 18
    ## 
    ## $utilisation_nurse
    ## [1] 3
    ## 
    ## $mean_queue_length_nurse
    ## [1] 21
    ## 
    ## $mean_time_in_system
    ## [1] 3
    ## 
    ## $mean_patients_in_service
    ## [1] 3
    ## 
    ## $mean_waiting_time_nurse
    ## [1] 24
    ## 
    ## $utilisation_nurse
    ## [1] 3
    ## 
    ## $mean_queue_length_nurse
    ## [1] 26
    ## 
    ## $mean_time_in_system
    ## [1] 3
    ## 
    ## $mean_patients_in_service
    ## [1] 3
    ## 
    ## $mean_waiting_time_nurse
    ## [1] 22
    ## 
    ## $utilisation_nurse
    ## [1] 3
    ## 
    ## $mean_queue_length_nurse
    ## [1] 24
    ## 
    ## $mean_time_in_system
    ## [1] 3
    ## 
    ## $mean_patients_in_service
    ## [1] 4
    ## 
    ## $mean_waiting_time_nurse
    ## [1] 15
    ## 
    ## $utilisation_nurse
    ## [1] 3
    ## 
    ## $mean_queue_length_nurse
    ## [1] 17
    ## 
    ## $mean_time_in_system
    ## [1] 3
    ## 
    ## $mean_patients_in_service
    ## [1] 3
    ## 
    ## $mean_waiting_time_nurse
    ## [1] 17
    ## 
    ## $utilisation_nurse
    ## [1] 4
    ## 
    ## $mean_queue_length_nurse
    ## [1] 19
    ## 
    ## $mean_time_in_system
    ## [1] 4
    ## 
    ## $mean_patients_in_service
    ## [1] 4
    ## 
    ## $mean_waiting_time_nurse
    ## [1] 20
    ## 
    ## $utilisation_nurse
    ## [1] 3
    ## 
    ## $mean_queue_length_nurse
    ## [1] 22
    ## 
    ## $mean_time_in_system
    ## [1] 3
    ## 
    ## $mean_patients_in_service
    ## [1] 3
    ## 
    ## $mean_waiting_time_nurse
    ## [1] 16
    ## 
    ## $utilisation_nurse
    ## [1] 3
    ## 
    ## $mean_queue_length_nurse
    ## [1] 21
    ## 
    ## $mean_time_in_system
    ## [1] 3
    ## 
    ## $mean_patients_in_service
    ## [1] 3
    ## 
    ## $mean_waiting_time_nurse
    ## [1] 15
    ## 
    ## $utilisation_nurse
    ## [1] 3
    ## 
    ## $mean_queue_length_nurse
    ## [1] 17
    ## 
    ## $mean_time_in_system
    ## [1] 3
    ## 
    ## $mean_patients_in_service
    ## [1] 3
    ## 
    ## $mean_waiting_time_nurse
    ## [1] 19
    ## 
    ## $utilisation_nurse
    ## [1] 3
    ## 
    ## $mean_queue_length_nurse
    ## [1] 20
    ## 
    ## $mean_time_in_system
    ## [1] 3
    ## 
    ## $mean_patients_in_service
    ## [1] 3

## Chosen number of replications

Given the variations observed using the algorithm in the sensitivity
analysis, decided appropriate number of replications to be **25**.

## Explanation of the automated method

This section walks through how the automation code is structured. The
algorithm that determines the number of replications is
`ReplicationsAlgorithm`. This depends on other R6 classes including
`WelfordStats` and `ReplicationTabuliser`.

### WelfordStats

`WelfordStats` is designed to:

- Keep a **running mean and sum of squares**.
- Return **other statistics** based on these (e.g. standard deviation,
  confidence intervals).
- **Call the `update()`** method of `ReplicationTabuliser` whenever a
  new data point is processed by `WelfordStats`

#### How do the running mean and sum of squares calculations work?

The running mean and sum of squares are updated iteratively with each
new data point provided, **without requiring the storage of all previous
data points**. This approach can be referred to as “online” because we
only need to store a small set of values (such as the current mean and
sum of squares), rather than maintaining an entire list of past values.

For example, focusing on the mean, normally you would need to store all
the data points in a list and sum them up to compute the average - for
example:

    data_points <- c(1, 2, 3, 4, 5)
    mean <- sum(data_points) / length(data_points)

This works fine for small datasets, but as the data grows, maintaining
the entire list becomes impractical. Instead, we can update the mean
without storing the previous data points using **Welford’s online
algorithm**. The formula for the running mean is:

$$
\mu_n = \mu_{n-1} + \frac{x_n - \mu_{n-1}}{n}
$$

Where:

- $\mu_n$ is the running mean after the $n$-th data point.
- $x_n$ is the new data point.
- $\mu_{n-1}$ is the running mean before the new data point.

The key thing to notice here is that, to update the mean, **all we
needed to know was the current running mean, the new data point, and the
number of data points**. A similar formula exists for calculating the
sum of squares.

In our code, every time we call `update()` with a new data point, the
mean and sum of squares are adjusted, with `n` keeping track of the
number of data points so far - for example:

    WelfordStats <- R6Class("WelfordStats", list( # nolint: object_name_linter

      n = 0L,
      mean = NA,
      ...

      update = function(x) {
        self$n <- self$n + 1L
        ...
          updated_mean <- self$mean + ((x - self$mean) / self$n)
          ...
          self$mean <- updated_meam
          ...

#### What other statistics can it calculate?

`WelfordStats` then has a series of methods which can return other
statistics based on the current mean, sum of squares, and count:

- Variance
- Standard deviation
- Standard error
- Half width of the confidence interval
- Lower confidence interval bound
- Upper confidence interval bound
- Deviation of confidence interval from the mean

### ReplicationTabuliser

`ReplicationTabuliser` keeps track of our results. It:

- Stores **lists with various statistics**, which are updated whenever
  `update()` is called.
- Can convert these into a **dataframe** using the `summary_table()`
  method.

<figure>
<img src="../images/replications_statistics.png"
alt="Interaction between WelfordStats and ReplicationTabuliser" />
<figcaption aria-hidden="true">Interaction between WelfordStats and
ReplicationTabuliser</figcaption>
</figure>

### ReplicationsAlgorithm

The diagram below is a visual representation of the logic in the
**ReplicationsAlgorithm**.

Once set up with the relevant parameters, it will first check if there
are **initial_replications** to run. These might be specified if the
user knows that the model will need at least X amount of replications
before any metrics start to get close to the desired precision. The
benefit of specifying these is that they are run using **runner()** and
so can be run in parallel if chosen.

Once these are run, it checks if any metrics meet precision already.
Typically more replications will be required (for the length of the
lookahead period) - but if there is no lookahead, they can be marked as
solved.

> **What is the lookahead period?**
>
> We want to make sure that the desired precision is stable and
> maintained for several replications. Here, we refer to this as the
> lookahead period.
>
> The user will specify **look_ahead** - as noted in
> [sim-tools](https://sim-tools.github.io/sim-tools/04_replications/01_automated_reps.html),
> this is recommended to be **5** by [Hoad et
> al. (2010)](https://www.jstor.org/stable/40926090).
>
> The algorithm contains a method **klimit()** which will scale up the
> lookahead if more than 100 replications have been run, to ensure a
> sufficient period is being checked for stability, relative to the
> number of replications. This is simply:
> `look_ahead/100 * replications`. For example, if we have run 200
> replications and look_ahead is 5: `5/100 * 200 = 10`.

After any initial replications, the algorithm enters a while loop. This
continues until all metrics are solved or the number of replications
surpasses the user-specified **replication_budget** - whichever comes
first!

With each loop, it runs the model for another replication, then updates
the results for any unsolved metrics from this replication, and checks
if precision is met. The **target_met** is a record of how many times in
a row precision has been met - once this passes the lookahead period,
the metric is marked as solved.

<figure>
<img src="../images/replications_algorithm.png"
alt="Visual representation of logic in ReplicationsAlgorithm" />
<figcaption aria-hidden="true">Visual representation of logic in
ReplicationsAlgorithm</figcaption>
</figure>

## Run time

``` r
# Get run time in seconds
end_time <- Sys.time()
runtime <- as.numeric(end_time - start_time, units = "secs")

# Display converted to minutes and seconds
minutes <- as.integer(runtime / 60L)
seconds <- as.integer(runtime %% 60L)
cat(sprintf("Notebook run time: %dm %ds", minutes, seconds))
```

    ## Notebook run time: 3m 46s
