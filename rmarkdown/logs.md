Logs
================
Amy Heather
2025-03-04

- [Set up](#set-up)
- [Simulation run with logs](#simulation-run-with-logs)
- [Calculate run time](#calculate-run-time)

Simmer has a `verbose` setting which will output activity information if
set to TRUE. Currently, this would be information on each patient as
they arrive and then see the nurse. Therefore, it is only best used when
running the simulation for a short time with few patients.

In this example, the log prints to screen as we have set
`log_to_console` to TRUE. This could also be saved to a file by setting
`log_to_file` to TRUE and providing a `file_path` in `param`.

## Set up

Install the latest version of the local simulation package.

``` r
devtools::load_all()
```

    ## ℹ Loading simulation

Start timer.

``` r
start_time <- Sys.time()
```

## Simulation run with logs

``` r
param <- parameters(
  data_collection_period = 100L,
  number_of_runs = 1L,
  cores = 1L,
  log_to_console = TRUE
)
verbose_run <- model(run_number = 0L, param = param)
```

    ##   [1] "Parameters:"                                                                                                                                                                                   
    ##   [2] "patient_inter=4; mean_n_consult_time=10; number_of_nurses=5; data_collection_period=100; number_of_runs=1; scenario_name=NULL; cores=1; log_to_console=TRUE; log_to_file=FALSE; file_path=NULL"
    ##   [3] "Log:"                                                                                                                                                                                          
    ##   [4] "         0 |    source: patient          |       new: patient0         | 0.736146"                                                                                                             
    ##   [5] "  0.736146 |   arrival: patient0         |  activity: Seize            | nurse, 1, 0 paths"                                                                                                    
    ##   [6] "  0.736146 |  resource: nurse            |   arrival: patient0         | SERVE"                                                                                                                
    ##   [7] "  0.736146 |    source: patient          |       new: patient1         | 1.31897"                                                                                                              
    ##   [8] "  0.736146 |   arrival: patient0         |  activity: Timeout          | function()"                                                                                                           
    ##   [9] "   1.31897 |   arrival: patient1         |  activity: Seize            | nurse, 1, 0 paths"                                                                                                    
    ##  [10] "   1.31897 |  resource: nurse            |   arrival: patient1         | SERVE"                                                                                                                
    ##  [11] "   1.31897 |    source: patient          |       new: patient2         | 3.06325"                                                                                                              
    ##  [12] "   1.31897 |   arrival: patient1         |  activity: Timeout          | function()"                                                                                                           
    ##  [13] "    2.1341 |   arrival: patient0         |  activity: Release          | nurse, 1"                                                                                                             
    ##  [14] "    2.1341 |  resource: nurse            |   arrival: patient0         | DEPART"                                                                                                               
    ##  [15] "    2.1341 |      task: Post-Release     |          :                  | "                                                                                                                     
    ##  [16] "   3.06325 |   arrival: patient2         |  activity: Seize            | nurse, 1, 0 paths"                                                                                                    
    ##  [17] "   3.06325 |  resource: nurse            |   arrival: patient2         | SERVE"                                                                                                                
    ##  [18] "   3.06325 |    source: patient          |       new: patient3         | 7.9815"                                                                                                               
    ##  [19] "   3.06325 |   arrival: patient2         |  activity: Timeout          | function()"                                                                                                           
    ##  [20] "    7.9815 |   arrival: patient3         |  activity: Seize            | nurse, 1, 0 paths"                                                                                                    
    ##  [21] "    7.9815 |  resource: nurse            |   arrival: patient3         | SERVE"                                                                                                                
    ##  [22] "    7.9815 |    source: patient          |       new: patient4         | 11.8078"                                                                                                              
    ##  [23] "    7.9815 |   arrival: patient3         |  activity: Timeout          | function()"                                                                                                           
    ##  [24] "   8.46008 |   arrival: patient2         |  activity: Release          | nurse, 1"                                                                                                             
    ##  [25] "   8.46008 |  resource: nurse            |   arrival: patient2         | DEPART"                                                                                                               
    ##  [26] "   8.46008 |      task: Post-Release     |          :                  | "                                                                                                                     
    ##  [27] "   9.45196 |   arrival: patient3         |  activity: Release          | nurse, 1"                                                                                                             
    ##  [28] "   9.45196 |  resource: nurse            |   arrival: patient3         | DEPART"                                                                                                               
    ##  [29] "   9.45196 |      task: Post-Release     |          :                  | "                                                                                                                     
    ##  [30] "   11.8078 |   arrival: patient4         |  activity: Seize            | nurse, 1, 0 paths"                                                                                                    
    ##  [31] "   11.8078 |  resource: nurse            |   arrival: patient4         | SERVE"                                                                                                                
    ##  [32] "   11.8078 |    source: patient          |       new: patient5         | 17.3707"                                                                                                              
    ##  [33] "   11.8078 |   arrival: patient4         |  activity: Timeout          | function()"                                                                                                           
    ##  [34] "   17.3707 |   arrival: patient5         |  activity: Seize            | nurse, 1, 0 paths"                                                                                                    
    ##  [35] "   17.3707 |  resource: nurse            |   arrival: patient5         | SERVE"                                                                                                                
    ##  [36] "   17.3707 |    source: patient          |       new: patient6         | 22.3211"                                                                                                              
    ##  [37] "   17.3707 |   arrival: patient5         |  activity: Timeout          | function()"                                                                                                           
    ##  [38] "   19.4281 |   arrival: patient4         |  activity: Release          | nurse, 1"                                                                                                             
    ##  [39] "   19.4281 |  resource: nurse            |   arrival: patient4         | DEPART"                                                                                                               
    ##  [40] "   19.4281 |      task: Post-Release     |          :                  | "                                                                                                                     
    ##  [41] "   22.3211 |   arrival: patient6         |  activity: Seize            | nurse, 1, 0 paths"                                                                                                    
    ##  [42] "   22.3211 |  resource: nurse            |   arrival: patient6         | SERVE"                                                                                                                
    ##  [43] "   22.3211 |    source: patient          |       new: patient7         | 26.5393"                                                                                                              
    ##  [44] "   22.3211 |   arrival: patient6         |  activity: Timeout          | function()"                                                                                                           
    ##  [45] "   26.5393 |   arrival: patient7         |  activity: Seize            | nurse, 1, 0 paths"                                                                                                    
    ##  [46] "   26.5393 |  resource: nurse            |   arrival: patient7         | SERVE"                                                                                                                
    ##  [47] "   26.5393 |    source: patient          |       new: patient8         | 34.0434"                                                                                                              
    ##  [48] "   26.5393 |   arrival: patient7         |  activity: Timeout          | function()"                                                                                                           
    ##  [49] "   30.2687 |   arrival: patient1         |  activity: Release          | nurse, 1"                                                                                                             
    ##  [50] "   30.2687 |  resource: nurse            |   arrival: patient1         | DEPART"                                                                                                               
    ##  [51] "   30.2687 |      task: Post-Release     |          :                  | "                                                                                                                     
    ##  [52] "   32.6736 |   arrival: patient6         |  activity: Release          | nurse, 1"                                                                                                             
    ##  [53] "   32.6736 |  resource: nurse            |   arrival: patient6         | DEPART"                                                                                                               
    ##  [54] "   32.6736 |      task: Post-Release     |          :                  | "                                                                                                                     
    ##  [55] "   33.0868 |   arrival: patient7         |  activity: Release          | nurse, 1"                                                                                                             
    ##  [56] "   33.0868 |  resource: nurse            |   arrival: patient7         | DEPART"                                                                                                               
    ##  [57] "   33.0868 |      task: Post-Release     |          :                  | "                                                                                                                     
    ##  [58] "   34.0434 |   arrival: patient8         |  activity: Seize            | nurse, 1, 0 paths"                                                                                                    
    ##  [59] "   34.0434 |  resource: nurse            |   arrival: patient8         | SERVE"                                                                                                                
    ##  [60] "   34.0434 |    source: patient          |       new: patient9         | 35.3912"                                                                                                              
    ##  [61] "   34.0434 |   arrival: patient8         |  activity: Timeout          | function()"                                                                                                           
    ##  [62] "   35.3912 |   arrival: patient9         |  activity: Seize            | nurse, 1, 0 paths"                                                                                                    
    ##  [63] "   35.3912 |  resource: nurse            |   arrival: patient9         | SERVE"                                                                                                                
    ##  [64] "   35.3912 |    source: patient          |       new: patient10        | 44.8492"                                                                                                              
    ##  [65] "   35.3912 |   arrival: patient9         |  activity: Timeout          | function()"                                                                                                           
    ##  [66] "   39.9282 |   arrival: patient8         |  activity: Release          | nurse, 1"                                                                                                             
    ##  [67] "   39.9282 |  resource: nurse            |   arrival: patient8         | DEPART"                                                                                                               
    ##  [68] "   39.9282 |      task: Post-Release     |          :                  | "                                                                                                                     
    ##  [69] "   41.8101 |   arrival: patient9         |  activity: Release          | nurse, 1"                                                                                                             
    ##  [70] "   41.8101 |  resource: nurse            |   arrival: patient9         | DEPART"                                                                                                               
    ##  [71] "   41.8101 |      task: Post-Release     |          :                  | "                                                                                                                     
    ##  [72] "   44.8492 |   arrival: patient10        |  activity: Seize            | nurse, 1, 0 paths"                                                                                                    
    ##  [73] "   44.8492 |  resource: nurse            |   arrival: patient10        | SERVE"                                                                                                                
    ##  [74] "   44.8492 |    source: patient          |       new: patient11        | 46.0257"                                                                                                              
    ##  [75] "   44.8492 |   arrival: patient10        |  activity: Timeout          | function()"                                                                                                           
    ##  [76] "   46.0257 |   arrival: patient11        |  activity: Seize            | nurse, 1, 0 paths"                                                                                                    
    ##  [77] "   46.0257 |  resource: nurse            |   arrival: patient11        | SERVE"                                                                                                                
    ##  [78] "   46.0257 |    source: patient          |       new: patient12        | 46.45"                                                                                                                
    ##  [79] "   46.0257 |   arrival: patient11        |  activity: Timeout          | function()"                                                                                                           
    ##  [80] "     46.45 |   arrival: patient12        |  activity: Seize            | nurse, 1, 0 paths"                                                                                                    
    ##  [81] "     46.45 |  resource: nurse            |   arrival: patient12        | SERVE"                                                                                                                
    ##  [82] "     46.45 |    source: patient          |       new: patient13        | 48.7649"                                                                                                              
    ##  [83] "     46.45 |   arrival: patient12        |  activity: Timeout          | function()"                                                                                                           
    ##  [84] "   46.6201 |   arrival: patient11        |  activity: Release          | nurse, 1"                                                                                                             
    ##  [85] "   46.6201 |  resource: nurse            |   arrival: patient11        | DEPART"                                                                                                               
    ##  [86] "   46.6201 |      task: Post-Release     |          :                  | "                                                                                                                     
    ##  [87] "   48.7649 |   arrival: patient13        |  activity: Seize            | nurse, 1, 0 paths"                                                                                                    
    ##  [88] "   48.7649 |  resource: nurse            |   arrival: patient13        | SERVE"                                                                                                                
    ##  [89] "   48.7649 |    source: patient          |       new: patient14        | 53.4581"                                                                                                              
    ##  [90] "   48.7649 |   arrival: patient13        |  activity: Timeout          | function()"                                                                                                           
    ##  [91] "   50.5079 |   arrival: patient10        |  activity: Release          | nurse, 1"                                                                                                             
    ##  [92] "   50.5079 |  resource: nurse            |   arrival: patient10        | DEPART"                                                                                                               
    ##  [93] "   50.5079 |      task: Post-Release     |          :                  | "                                                                                                                     
    ##  [94] "   53.4581 |   arrival: patient14        |  activity: Seize            | nurse, 1, 0 paths"                                                                                                    
    ##  [95] "   53.4581 |  resource: nurse            |   arrival: patient14        | SERVE"                                                                                                                
    ##  [96] "   53.4581 |    source: patient          |       new: patient15        | 59.1992"                                                                                                              
    ##  [97] "   53.4581 |   arrival: patient14        |  activity: Timeout          | function()"                                                                                                           
    ##  [98] "   53.8308 |   arrival: patient14        |  activity: Release          | nurse, 1"                                                                                                             
    ##  [99] "   53.8308 |  resource: nurse            |   arrival: patient14        | DEPART"                                                                                                               
    ## [100] "   53.8308 |      task: Post-Release     |          :                  | "                                                                                                                     
    ## [101] "    58.733 |   arrival: patient13        |  activity: Release          | nurse, 1"                                                                                                             
    ## [102] "    58.733 |  resource: nurse            |   arrival: patient13        | DEPART"                                                                                                               
    ## [103] "    58.733 |      task: Post-Release     |          :                  | "                                                                                                                     
    ## [104] "   59.1992 |   arrival: patient15        |  activity: Seize            | nurse, 1, 0 paths"                                                                                                    
    ## [105] "   59.1992 |  resource: nurse            |   arrival: patient15        | SERVE"                                                                                                                
    ## [106] "   59.1992 |    source: patient          |       new: patient16        | 60.4953"                                                                                                              
    ## [107] "   59.1992 |   arrival: patient15        |  activity: Timeout          | function()"                                                                                                           
    ## [108] "   60.4953 |   arrival: patient16        |  activity: Seize            | nurse, 1, 0 paths"                                                                                                    
    ## [109] "   60.4953 |  resource: nurse            |   arrival: patient16        | SERVE"                                                                                                                
    ## [110] "   60.4953 |    source: patient          |       new: patient17        | 61.3093"                                                                                                              
    ## [111] "   60.4953 |   arrival: patient16        |  activity: Timeout          | function()"                                                                                                           
    ## [112] "   61.3093 |   arrival: patient17        |  activity: Seize            | nurse, 1, 0 paths"                                                                                                    
    ## [113] "   61.3093 |  resource: nurse            |   arrival: patient17        | SERVE"                                                                                                                
    ## [114] "   61.3093 |    source: patient          |       new: patient18        | 62.5163"                                                                                                              
    ## [115] "   61.3093 |   arrival: patient17        |  activity: Timeout          | function()"                                                                                                           
    ## [116] "     61.61 |   arrival: patient5         |  activity: Release          | nurse, 1"                                                                                                             
    ## [117] "     61.61 |  resource: nurse            |   arrival: patient5         | DEPART"                                                                                                               
    ## [118] "     61.61 |      task: Post-Release     |          :                  | "                                                                                                                     
    ## [119] "   62.5163 |   arrival: patient18        |  activity: Seize            | nurse, 1, 0 paths"                                                                                                    
    ## [120] "   62.5163 |  resource: nurse            |   arrival: patient18        | SERVE"                                                                                                                
    ## [121] "   62.5163 |    source: patient          |       new: patient19        | 65.5225"                                                                                                              
    ## [122] "   62.5163 |   arrival: patient18        |  activity: Timeout          | function()"                                                                                                           
    ## [123] "   64.8666 |   arrival: patient18        |  activity: Release          | nurse, 1"                                                                                                             
    ## [124] "   64.8666 |  resource: nurse            |   arrival: patient18        | DEPART"                                                                                                               
    ## [125] "   64.8666 |      task: Post-Release     |          :                  | "                                                                                                                     
    ## [126] "   65.5225 |   arrival: patient19        |  activity: Seize            | nurse, 1, 0 paths"                                                                                                    
    ## [127] "   65.5225 |  resource: nurse            |   arrival: patient19        | SERVE"                                                                                                                
    ## [128] "   65.5225 |    source: patient          |       new: patient20        | 69.842"                                                                                                               
    ## [129] "   65.5225 |   arrival: patient19        |  activity: Timeout          | function()"                                                                                                           
    ## [130] "   68.5615 |   arrival: patient17        |  activity: Release          | nurse, 1"                                                                                                             
    ## [131] "   68.5615 |  resource: nurse            |   arrival: patient17        | DEPART"                                                                                                               
    ## [132] "   68.5615 |      task: Post-Release     |          :                  | "                                                                                                                     
    ## [133] "    69.842 |   arrival: patient20        |  activity: Seize            | nurse, 1, 0 paths"                                                                                                    
    ## [134] "    69.842 |  resource: nurse            |   arrival: patient20        | SERVE"                                                                                                                
    ## [135] "    69.842 |    source: patient          |       new: patient21        | 75.011"                                                                                                               
    ## [136] "    69.842 |   arrival: patient20        |  activity: Timeout          | function()"                                                                                                           
    ## [137] "   70.7225 |   arrival: patient16        |  activity: Release          | nurse, 1"                                                                                                             
    ## [138] "   70.7225 |  resource: nurse            |   arrival: patient16        | DEPART"                                                                                                               
    ## [139] "   70.7225 |      task: Post-Release     |          :                  | "                                                                                                                     
    ## [140] "   72.4039 |   arrival: patient15        |  activity: Release          | nurse, 1"                                                                                                             
    ## [141] "   72.4039 |  resource: nurse            |   arrival: patient15        | DEPART"                                                                                                               
    ## [142] "   72.4039 |      task: Post-Release     |          :                  | "                                                                                                                     
    ## [143] "    75.011 |   arrival: patient21        |  activity: Seize            | nurse, 1, 0 paths"                                                                                                    
    ## [144] "    75.011 |  resource: nurse            |   arrival: patient21        | SERVE"                                                                                                                
    ## [145] "    75.011 |    source: patient          |       new: patient22        | 77.2296"                                                                                                              
    ## [146] "    75.011 |   arrival: patient21        |  activity: Timeout          | function()"                                                                                                           
    ## [147] "   75.8049 |   arrival: patient19        |  activity: Release          | nurse, 1"                                                                                                             
    ## [148] "   75.8049 |  resource: nurse            |   arrival: patient19        | DEPART"                                                                                                               
    ## [149] "   75.8049 |      task: Post-Release     |          :                  | "                                                                                                                     
    ## [150] "   77.2296 |   arrival: patient22        |  activity: Seize            | nurse, 1, 0 paths"                                                                                                    
    ## [151] "   77.2296 |  resource: nurse            |   arrival: patient22        | SERVE"                                                                                                                
    ## [152] "   77.2296 |    source: patient          |       new: patient23        | 82.4021"                                                                                                              
    ## [153] "   77.2296 |   arrival: patient22        |  activity: Timeout          | function()"                                                                                                           
    ## [154] "   78.0239 |   arrival: patient21        |  activity: Release          | nurse, 1"                                                                                                             
    ## [155] "   78.0239 |  resource: nurse            |   arrival: patient21        | DEPART"                                                                                                               
    ## [156] "   78.0239 |      task: Post-Release     |          :                  | "                                                                                                                     
    ## [157] "    82.373 |   arrival: patient20        |  activity: Release          | nurse, 1"                                                                                                             
    ## [158] "    82.373 |  resource: nurse            |   arrival: patient20        | DEPART"                                                                                                               
    ## [159] "    82.373 |      task: Post-Release     |          :                  | "                                                                                                                     
    ## [160] "   82.4021 |   arrival: patient23        |  activity: Seize            | nurse, 1, 0 paths"                                                                                                    
    ## [161] "   82.4021 |  resource: nurse            |   arrival: patient23        | SERVE"                                                                                                                
    ## [162] "   82.4021 |    source: patient          |       new: patient24        | 84.4588"                                                                                                              
    ## [163] "   82.4021 |   arrival: patient23        |  activity: Timeout          | function()"                                                                                                           
    ## [164] "   84.4588 |   arrival: patient24        |  activity: Seize            | nurse, 1, 0 paths"                                                                                                    
    ## [165] "   84.4588 |  resource: nurse            |   arrival: patient24        | SERVE"                                                                                                                
    ## [166] "   84.4588 |    source: patient          |       new: patient25        | 86.1478"                                                                                                              
    ## [167] "   84.4588 |   arrival: patient24        |  activity: Timeout          | function()"                                                                                                           
    ## [168] "   86.0393 |   arrival: patient12        |  activity: Release          | nurse, 1"                                                                                                             
    ## [169] "   86.0393 |  resource: nurse            |   arrival: patient12        | DEPART"                                                                                                               
    ## [170] "   86.0393 |      task: Post-Release     |          :                  | "                                                                                                                     
    ## [171] "   86.1478 |   arrival: patient25        |  activity: Seize            | nurse, 1, 0 paths"                                                                                                    
    ## [172] "   86.1478 |  resource: nurse            |   arrival: patient25        | SERVE"                                                                                                                
    ## [173] "   86.1478 |    source: patient          |       new: patient26        | 99.0189"                                                                                                              
    ## [174] "   86.1478 |   arrival: patient25        |  activity: Timeout          | function()"                                                                                                           
    ## [175] "   87.1752 |   arrival: patient22        |  activity: Release          | nurse, 1"                                                                                                             
    ## [176] "   87.1752 |  resource: nurse            |   arrival: patient22        | DEPART"                                                                                                               
    ## [177] "   87.1752 |      task: Post-Release     |          :                  | "                                                                                                                     
    ## [178] "   91.7261 |   arrival: patient25        |  activity: Release          | nurse, 1"                                                                                                             
    ## [179] "   91.7261 |  resource: nurse            |   arrival: patient25        | DEPART"                                                                                                               
    ## [180] "   91.7261 |      task: Post-Release     |          :                  | "                                                                                                                     
    ## [181] "   99.0189 |   arrival: patient26        |  activity: Seize            | nurse, 1, 0 paths"                                                                                                    
    ## [182] "   99.0189 |  resource: nurse            |   arrival: patient26        | SERVE"                                                                                                                
    ## [183] "   99.0189 |    source: patient          |       new: patient27        | 101.397"                                                                                                              
    ## [184] "   99.0189 |   arrival: patient26        |  activity: Timeout          | function()"

This will align with the recorded results of each patient.

``` r
# Compare to patient-level results
verbose_run[["arrivals"]]
```

    ##         name start_time  end_time activity_time resource replication
    ## 1   patient0  0.7361463  2.134099     1.3979526    nurse           0
    ## 2   patient2  3.0632477  8.460076     5.3968284    nurse           0
    ## 3   patient3  7.9814959  9.451956     1.4704599    nurse           0
    ## 4   patient4 11.8077659 19.428064     7.6202986    nurse           0
    ## 5   patient1  1.3189732 30.268659    28.9496854    nurse           0
    ## 6   patient6 22.3211206 32.673560    10.3524395    nurse           0
    ## 7   patient7 26.5392933 33.086760     6.5474664    nurse           0
    ## 8   patient8 34.0434340 39.928231     5.8847972    nurse           0
    ## 9   patient9 35.3911679 41.810094     6.4189259    nurse           0
    ## 10 patient11 46.0257105 46.620102     0.5943916    nurse           0
    ## 11 patient10 44.8492289 50.507884     5.6586552    nurse           0
    ## 12 patient14 53.4580992 53.830785     0.3726853    nurse           0
    ## 13 patient13 48.7648508 58.732980     9.9681296    nurse           0
    ## 14  patient5 17.3707064 61.610049    44.2393422    nurse           0
    ## 15 patient18 62.5162864 64.866561     2.3502745    nurse           0
    ## 16 patient17 61.3093226 68.561466     7.2521430    nurse           0
    ## 17 patient16 60.4952812 70.722540    10.2272588    nurse           0
    ## 18 patient15 59.1992406 72.403920    13.2046793    nurse           0
    ## 19 patient19 65.5224571 75.804926    10.2824690    nurse           0
    ## 20 patient21 75.0110283 78.023858     3.0128300    nurse           0
    ## 21 patient20 69.8419817 82.373035    12.5310535    nurse           0
    ## 22 patient12 46.4500010 86.039329    39.5893285    nurse           0
    ## 23 patient22 77.2295939 87.175152     9.9455579    nurse           0
    ## 24 patient25 86.1477594 91.726053     5.5782935    nurse           0
    ## 25 patient26 99.0189155        NA            NA    nurse           0
    ## 26 patient24 84.4587897        NA            NA    nurse           0
    ## 27 patient23 82.4020925        NA            NA    nurse           0
    ##    q_time_unseen
    ## 1             NA
    ## 2             NA
    ## 3             NA
    ## 4             NA
    ## 5             NA
    ## 6             NA
    ## 7             NA
    ## 8             NA
    ## 9             NA
    ## 10            NA
    ## 11            NA
    ## 12            NA
    ## 13            NA
    ## 14            NA
    ## 15            NA
    ## 16            NA
    ## 17            NA
    ## 18            NA
    ## 19            NA
    ## 20            NA
    ## 21            NA
    ## 22            NA
    ## 23            NA
    ## 24            NA
    ## 25     0.9810845
    ## 26    15.5412103
    ## 27    17.5979075

## Calculate run time

``` r
# Get run time in seconds
end_time <- Sys.time()
runtime <- as.numeric(end_time - start_time, units = "secs")

# Display converted to minutes and seconds
minutes <- as.integer(runtime / 60L)
seconds <- as.integer(runtime %% 60L)
print(sprintf("Notebook run time: %dm %ds", minutes, seconds))
```

    ## [1] "Notebook run time: 0m 0s"
