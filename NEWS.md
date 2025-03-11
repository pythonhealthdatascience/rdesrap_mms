# R DES RAP Template 0.2.0

Warm-up period, "unseen" metrics and tests. Note that the alteration to record service duration altered the order of random number generation, so results now differ from before.

## New features

* Add warm-up period (`filter_warmup()`).
* Add measurement of when service starts and its duration during the model run (`set_attribute("nurse_serve_start", ...` and `set_attribute("nurse_serve_length", ...`).
* Add count and wait time for unseen patients in the run results.
* Add tests for warm-up, unseen metrics, and logs.
* Add `arrivals` and `resources` to base case back test.

## Bug fixes

* Include all patients in the run results `arrivals` count (and not only those who completed the service).
* Include patients partway through service in the `mean_waiting_time` and `mean_service_time` (and not only those who completed the service).
* Use `devtools::install()` in `choosing_cores.Rmd` (required to get updated package for parallel processing).

## Other changes

* Simplify scenario back test.
* Add DOI and Zenodo citation to README.

# R DES RAP Template 0.1.0

🌱 First release of the R DES template.
