<div align="center">

# Simple M/M/s queuing model: R DES RAP

<!-- badges: start -->
![R 4.4.1](https://img.shields.io/badge/-R_4.4.1-276DC2?&logo=r&logoColor=white)
![MIT Licence](https://img.shields.io/badge/Licence-MIT-green.svg?&labelColor=gray)
[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.14980863.svg)](https://doi.org/10.5281/zenodo.14980863)
[![R-CMD-check](https://github.com/pythonhealthdatascience/rdesrap_mms/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/pythonhealthdatascience/rdesrap_mms/actions/workflows/R-CMD-check.yaml)
[![Lint](https://github.com/pythonhealthdatascience/rdesrap_mms/actions/workflows/lint.yaml/badge.svg)](https://github.com/pythonhealthdatascience/rdesrap_mms/actions/workflows/lint.yaml)
[![ORCID](https://img.shields.io/badge/ORCID_Amy_Heather-0000--0002--6596--3479-A6CE39?&logo=orcid&logoColor=white)](https://orcid.org/0000-0002-6596-3479)
[![Codecov test coverage](https://codecov.io/gh/pythonhealthdatascience/rdesrap_mms/graph/badge.svg)](https://app.codecov.io/gh/pythonhealthdatascience/rdesrap_mms)
<!-- badges: end -->
</div>

<br>

This repository is an example accompanying the [**DES RAP Book**](https://github.com/pythonhealthdatascience/des_rap_book) — an open educational resource on reproducible discrete-event simulation (DES) in Python and R. The book demonstrates best practices for building, validating, and sharing DES models within a reproducible analytical pipeline (RAP). The `rdesrap_mms` model illustrates how these principles can be applied to a simple queueing model.

<br>

## Repository overview

This repository provides a reproducible analytical pipeline (RAP) for a simple **M/M/s queuing model** implemented in R using simmer. The model simulates patients arriving, waiting to see a nurse, being served, and leaving. All code is structured as a local R package.

![](images/nurse_des.drawio.png)

An M/M/s queueing model is a classic mathematical model for systems where:

* Arrivals happen at random, following a Poisson process - and the time between arrivals follows an exponential distribution (the first "M", which stands for "Markovian" as it is memoryless - arrivals are independent).
* Service times are exponential (second "M").
* There are s parallel servers (e.g. nurses) sharing a single queue.

This type of model is widely used for studying waiting lines in healthcare, call centers, and other service systems. It helps answer questions like: How long will people wait? How many servers are needed to keep waits short? The only required inputs are the average arrival rate, average service time, and the number of servers.

<br>

## Usage and reproduction instructions

<details><summary><b>Installation</b></summary>

Clone the repository:

```{.r}
git clone https://github.com/pythonhealthdatascience/rdesrap_mms.git
cd rdesrap_mms
```

Set up the R environment using `renv` (recommended):

```{.r}
renv::init()
renv::restore()
```

If you encounter issues restoring the exact environment, you can install dependencies from `DESCRIPTION` and generate your own lock file:

```{.r}
renv::init()
renv::install()
renv::snapshot()
```

**System dependencies:** Some packages (e.g. `igraph`) may require system libraries. For example, for Ubuntu:

```{.bash}
sudo apt install build-essential gfortran
sudo apt install libglpk-dev libxml2-dev
```

</details>

<br>

<details><summary><b>How to run</b></summary>

The simulation code is in the `R/` folder as a local package. Example analyses and model runs are in `rmarkdown/`.

**Install the local package:**

```{.r}
devtools::install()
library(simulation)
```

**Run a single simulation:**

```{.r}
params <- parameters(patient_inter = 2L, mean_n_consult_time = 4L, number_of_nurses = 2L)
result <- model(run_number = 1L, param = params)
```

**Run multiple replications:**

```{.r}
params <- parameters(patient_inter = 2L, mean_n_consult_time = 4L, number_of_nurses = 2L, number_of_runs = 10L)
results <- runner(param = params)
```

**Run all example analyses (from command line):**

```{.bash}
bash run_rmarkdown.sh
```

</details>

<br>

<details><summary><b>Input data</b></summary>

**Patient-level data** for our system is provided in the file: `inst/extdata/NHS_synthetic.csv`.

**Data dictionary** (explaining each field) is available in: `inst/extdata/NHS_synthetic_dictionary.csv`.

This dataset is **synthetic** and was generated in the [pydesrap_mms](https://github.com/pythonhealthdatascience/pydesrap_mms) repository based on the the structure of some fields from the [Emergency Care Data Set (ECDS)](https://digital.nhs.uk/data-and-information/data-collections-and-data-sets/data-sets/emergency-care-data-set-ecds). The data generation process involved:

* **Arrivals:** Sampled from a Poisson distribution (average 15 patients per hour).
* **Wait times:** Sampled from an exponential distribution (average wait time: 5 minutes).
* **Service times:** Sampled from an exponential distribution (average service time: 10 minutes).
* **Time period:** Data covers one full year (1st January - 31st December 2025).

This dataset is released under the MIT licence. If you use this data, please cite the original repository: [pydesrap_mms](https://github.com/pythonhealthdatascience/pydesrap_mms).

The code for input modelling is in: `rmarkdown/input_modelling.Rmd`. Model parameters are determined in this file and then stored in: `R/parameters.R`. Description for each parameter can be found in the class docstring within this file.

</details>

<br>

<details><summary><b>Reproducing results</b></summary>

To generate the figures and tables from the paper (`mock_paper.md`), execute:

* **Figure 1-4**: `rmarkdown/analysis.Rmd`
* **Figure A.1-A.2:** `rmarkdown/input_modelling.Rmd`
* **Figure B.1:** `rmarkdown/choosing_warmup.Rmd`
* **Figure C.1-C.3:** `rmarkdown/choosing_replications.Rmd`

</details>

<br>

<details><summary><b>Run time and machine specification</b></summary>

Run times from our analyses (on Intel Core i7-12700H, 32GB RAM, Ubuntu 24.04.1):

* `analysis.Rmd`: 3m 24s
* `choosing_cores.Rmd`: 0m 45s
* `choosing_replications.Rmd`: 1m 20s
* `choosing_warmup.Rmd`: 4s
* `generate_exp_results.Rmd`: 7s
* `input_modelling.Rmd`: 8s

There are also two notebooks illustrating logging functionality (`logs.Rmd`) and about the impact of using `set_attributes()` and `get_attributes` (`using_set_attributes.Rmd`).

</details>

<br>

## Project details and credits

### How to cite the repository

If you use this repository, please cite either the GitHub repository or Zenodo:

> Heather, A. & Monks, T. (2025). Simple M/M/s queuing model: R DES RAP. GitHub. https://github.com/pythonhealthdatascience/rdesrap_mms.
>
> Heather, A. & Monks, T. (2025). Simple M/M/s queuing model: R DES RAP. Zenodo. https://doi.org/10.5281/zenodo.14980863.

### Contributors

**Amy Heather** - developed the repository.

* [![ORCID](https://img.shields.io/badge/ORCID-0000--0002--6596--3479-A6CE39?style=for-the-badge&logo=orcid&logoColor=white)](https://orcid.org/0000-0002-6596-3479)
* [![GitHub](https://img.shields.io/badge/GitHub-amyheather-181717?style=for-the-badge&logo=github&logoColor=white)](https://github.com/amyheather)

**Tom Monks** - peer review of the repository.

* [![ORCID](https://img.shields.io/badge/ORCID-0000--0003--2631--4481-A6CE39?style=for-the-badge&logo=orcid&logoColor=white)](https://orcid.org/0000-0003-2631-4481)
* [![GitHub](https://img.shields.io/badge/GitHub-TomMonks-181717?style=for-the-badge&logo=github&logoColor=white)](https://github.com/TomMonks)

### Licence

MIT Licence. See `LICENSE.md` for details.

### Community

Curious about contributing? Check out the [contributing guidelines](CONTRIBUTING.md) to learn how you can help. Every bit of help counts, and your contribution - no matter how minor - is highly valued.

### Acknowledgements

This repository was developed with thanks to a few others sources. These are acknowledged throughout in the relevant scipts, and also summarised here:

| Source | Find out more about how it was used... |
| - | - |
| Ucar I, Smeets B (2023). simmer.plot: Plotting Methods for 'simmer'. https://r-simmer.org. https://github.com/r-simmer/simmer.plot. | `R/get_run_results.R` |
| Tom Monks (2021) sim-tools: fundamental tools to support the simulation process in python (https://github.com/TomMonks/sim-tools) (MIT Licence).<br> Who themselves cite Hoad, Robinson, & Davies (2010). Automated selection of the number of replications for a discrete-event simulation (https://www.jstor.org/stable/40926090), and Knuth. D "The Art of Computer Programming" Vol 2. 2nd ed. Page 216. | `R/choose_replications.R` |

### Funding

This project was developed as part of the project STARS: Sharing Tools and Artefacts for Reproducible Simulations. It is supported by the Medical Research Council [grant number [MR/Z503915/1](https://gtr.ukri.org/projects?ref=MR%2FZ503915%2F1)].
