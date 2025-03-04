<div align="center">

# R DES RAP Template

<!-- badges: start -->
![R 4.4.1](https://img.shields.io/badge/-R_4.4.1-276DC2?logo=r&logoColor=white) <!--TODO Specify R version -->
![MIT Licence](https://img.shields.io/badge/Licence-MIT-green.svg?labelColor=gray)
[![R-CMD-check](https://github.com/pythonhealthdatascience/rap_template_r_des/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/pythonhealthdatascience/rap_template_r_des/actions/workflows/R-CMD-check.yaml)
[![Lint](https://github.com/pythonhealthdatascience/rap_template_r_des/actions/workflows/lint.yaml/badge.svg)](https://github.com/pythonhealthdatascience/rap_template_r_des/actions/workflows/lint.yaml)
<!-- badges: end -->
<!-- TODO: Add DOI -->

A template for creating **discrete-event simulation (DES)** models in R within a **reproducible analytical pipeline (RAP)**.<br><br>
Click on <kbd>Use this template</kbd> to initialise new repository.<br>
A `README` template is provided at the **end of this file**.

</div>

<br>

Table of contents:

* [📌 Introduction](#-introduction)
* [🧐 What are we modelling?](#-what-are-we-modelling)
* [🛠️ Using this template](#️-using-this-template)
* [❓ How does the model work?](#-how-does-the-model-work)
* [📂 Repository structure](#-repository-structure)
* [⏰ Run time and machine specification](#-run-time-and-machine-specification)
* [📝 Citation](#-citation)
* [📜 Licence](#-licence)
* [💰 Funding](#-funding)
* [📄 Template README for your project](#-template-readme-for-your-project)

<br>

## 📌 Introduction

This repository provides a template for building discrete-event simulation (DES) models in R.

😊 **Simple:** Easy-to-follow code structure using [simmer](https://r-simmer.org/). Implements a simple M/M/s queueing model in which patients arrive, wait to see a nurse, have a consultation with the nurse and then leave.

♻️ **Reproducible:** This template is designed to function as a RAP. It adheres to reproducibility recommendations from:

* ["Levels of RAP" framework](https://nhsdigital.github.io/rap-community-of-practice/introduction_to_RAP/levels_of_RAP/) from the NHS RAP Community of Practice (as documented in `nhs_rap.md`).
* Recommendations from [Heather et al. 2025](TODO:ADDLINK) "*On the reproducibility of discrete-event simulation studies in health research: a computational investigation using open models*" (as documented in `heather_2025.md`).

✨ **Design practices:** Functions are documented with `roxygen2` docstrings and `lintr` is used to lint `.R` and `.Rmd` files.

🧱 **Package structure:** The simulation code (`R/`) is structured as a little local R package. It is installed in our environment using `devtools::install()` and then `library(simulation)`. This means it can easily be used anywhere else in the directory - here, in `rmarkdown/` and `tests/` - without needing any additional code (e.g. no need to run `source()` with paths to the files).

<details markdown="1">
<summary><b>More information about the package structure</b></summary>

<br>

**Rationale:** As explained above, the package structure is helpful for sourcing the simulation code anywhere in the folder. Other benefits of this structure include:

* Encourages well-organised repository following **standardised** established R package structure, which ensures that the model and analysis code are kept seperate.
* Useful "built-in" features like **tests**, documentation of functions using **Roxygen**, documentation of data, and **package checks** (e.g. checking all imports are declared).
* If your analysis has a short run time, the `.Rmd` files could be stored in a `vignettes/` folder which will mean they **re-run with every package build/check**, and so any new run issues will be identified. However, in this project, the analysis was instead stored in `rmarkdown/` as the file paths to save outputs cause errors in `vignettes/` (as they will differ between your runs of the notebook, and runs during the package build process).
* Meet packaging **requirement** on the NHS "Levels of RAP" framework.

For more information on the rationale behind structuring research as an R package, check out:

* ["Open, Reproducible, and Distributable Research With R Packages"](https://dante-sttr.gitlab.io/r-open-science/) from the DANTE Project - for example, this page on [vignettes](https://dante-sttr.gitlab.io/r-open-science/reports-manuscripts.html).
* ["Sharing and organizing research products as R packages"](https://doi.org/10.3758/s13428-020-01436-x) from Vuorre and Crump 2020

**Commands:** Helpful commands when working with the package include:

* `devtools::document()` to reproduce documentation in `man/` after changes to the docstrings.
* `devtools::check()` to build and check the package follows best practices.
* `devtools::install()` to load the latest version of the package into your environment.
* `devtools::test()` to run the tests in `tests/`.

</details>

## 🧐 What are we modelling?

A **simulation** is a computer model that mimics a real-world system. It allows us to test different scenarios and see how the system behaves. One of the most common simulation types in healthcare is **DES**.

In DES models, time progresses only when **specific events** happen (e.g., a patient arriving or finishing treatment). Unlike a continuous system where time flows smoothly, DES jumps forward in steps between events. For example, when people (or tasks) arrive, wait for service, get served, and then leave.

![Simple DES Animation](images/simple_des.gif)
*Simple model animation created using web app developed by Sammi Rosser (2024) available at https://github.com/hsma-programme/Teaching_DES_Concepts_Streamlit and shared under an MIT Licence.*

One simple example of a DES model is the **M/M/s queueing model**, which is implemented in this template. In a DES model, we use well-known **statistical distributions** to describe the behaviour of real-world processes. In an M/M/s model we use:

* **Poisson distribution** to model patient arrivals - and so, equivalently, use an **exponential distribution** to model the inter-arrival times (time from one arrival to the next)
* **Exponential distribution** to model server times.

These can be referred to as Markovian assumptions (hence "M/M"), and "s" refers to the number of parallel servers available.

For this M/M/s model, you only need three inputs:

1. **Average arrival rate**: How often people typically arrive (e.g. patient arriving to clinic).
2. **Average service duration**: How long it takes to serve one person (e.g. doctor consultation time).
3. **Number of servers**: How many service points are available (e.g. number of doctors).

This model could be applied to a range of contexts, including:

| Queue | Server/Resource |
| - | - |
| Patients in a waiting room | Doctor's consultation
| Patients waiting for an ICU bed | Available ICU beds |
| Prescriptions waiting to be processed | Pharmacists preparing and dispensing medications |

For further information on M/M/s models, see:

* Ganesh, A. (2012). Simple queueing models. University of Bristol. https://people.maths.bris.ac.uk/~maajg/teaching/iqn/queues.pdf.
* Green, L. (2011). Queueing theory and modeling. In *Handbook of Healthcare Delivery Systems*. Taylor & Francis. https://business.columbia.edu/faculty/research/queueing-theory-and-modeling.

<br>

## 🛠️ Using this template

### Step 1: Create a new repository

1. Click on <kbd>Use this template</kbd>.
2. Provide a name and description for your new project repository.
3. Clone the repository locally: 

```
git clone https://github.com/username/repo
cd repo
```

### Step 2: Set-up the development environment

<!-- TODO: Test and consider options here, as not happy with this. Given I struggled with backdating R and packages, I think it would be appropriate here to divide this into two things:
(a) The exact environment we used (which we would encourage for RAP)
(b) Considerations re-running later, if not possible to rebuild that exact environment (e.g. which R, which packages, are compatible, maintenance, DESCRIPTION, etc). -->

Load the R environment described in the `renv.lock` file (though note this won't fetch the version of R used - you would need to switch to that manually first):

```
renv::init()
renv::restore()
```

If facing issues with restoring this environment, an alternative is to set up a fresh environment based on the `DESCRIPTION`, but note that this may then install more recent package versions.

```
renv::init()
renv::install()
renv::snapshot()
```

There may also be system dependencies. The exact requirements will depend on your operating system, whether you have used R before, and what packages you have used. For example, when developing the template, we had to install the following for `igraph` (as explained [in their documentation](https://r.igraph.org/articles/installation-troubleshooting.html)):

```
sudo apt install build-essential gfortran
sudo apt install libglpk-dev libxml2-dev
```

### Step 3: Explore and modify

🔎 Choose your desired licence (e.g. <https://choosealicense.com/>). If keeping an MIT licence, just modify the copyright holder in `LICENSE` and `LICENSE.md`.

🔎 Review the example DES implementation in `R/` and `rmarkdown/`. Modify and extend the code as needed for your specific use case.

🔎 Check you still fulfil the criteria in `docs/nhs_rap.md` and `docs/heather_2025.md`.

🔎 Adapt the template `README` provided at the end of this file.

🔎 Create your own `CITATION.cff` file using [cff-init](https://citation-file-format.github.io/cff-initializer-javascript/#/).

🔎 Update `DESCRIPTION` and entries in the current `NEWS.md` with your own details, versions, and create GitHub releases.

🔎 Archive your repository (e.g. [Zenodo](https://zenodo.org/)).

🔎 Complete the Strengthening The Reporting of Empirical Simulation Studies (STRESS) checklist (`stress_des.md`) and use this to support writing publication/report, and attach as an appendice to report.

🔎 **Tests**

To run tests:

```
devtools::test()
```

The repository contains a GitHub action `R-CMD-check.yaml` which will automatically run tests with new commits to GitHub, as part of the `devtools::check()` operation. This is continuous integration, helping to catch bugs early and keep the code stable. It will run the tests on three operating systems: Ubuntu, Windows and Mac.

<!--TODO: Double check this CI definitely flags test failures-->

🔎 **Linting**

You can lint the `.R` and `.Rmd` files by running:

```
lintr::lint_package()
lintr::lint_dir("rmarkdown")
```

The `lint_package()` function will run on files typically included in a package (i.e. `R/`, `tests/`). This will not include `rmarkdown/` as it is not typical/excluded from our package build, and so we can lint that by specifying the directory for `lint_dir()`.

<br>

## ❓ How does the model work?

TBC <!-- TODO: Write this section -->

**Note:** This template does not include a **warm-up period**, as it is not natively supported by simmer and was not possible to implement. This was explored - as the simulation results returned by `get_mon_arrivals()` can be filtered to only include patients arriving after a warm-up period. This isn't possible for the `get_mon_resources()` results (which we use to derive utilisation). This is because it provides times for each resource, but doesn't specify whether each time is a start or end time. We examine results per resource, and when there are multiple resources, it wouldn't be possible to match the resource times to the patient items (to identify which are start and end times), as the patients end time may be later if they had other resources to visit (and vice versa, their start time may be earlier if they visited other resources prior).

<br>

## 📂 Repository structure

```
repo/
├── .github/workflows/          # GitHub actions
├── docs/                       # Documentation
├── images/                     # Image files and GIFs
├── man/                        # Function documentation generated by roxygen
├── outputs/                    # Folder to save any outputs from model
├── R/                          # Local package containing code for the DES model
├── renv/                       # Instructions for creation of R environment
├── rmarkdown/                  # .Rmd files to run DES model and analyse results
├── tests/                      # Unit and back testing of the DES model
├── .gitignore                  # Untracked files
├── .lintr                      # Lintr settings
├── .Rbuildignore               # Files and directories to exclude when building the package
├── .Rprofile                   # R session configuration file
├── CITATION.cff                # How to cite the repository
├── CONTRIBUTING.md             # Contribution instructions
├── DESCRIPTION                 # Metadata for the R package, including dependencies
├── LICENSE                     # Licence file for the R package
├── LICENSE.md                  # MIT licence for the repository
├── NAMESPACE                   # Defines the exported functions and objects for the R package
├── NEWS.md                     # Describes changes between releases (equivalent to a changelog for R packages)
├── rap_template_r_des.Rproject # Project settings
├── README.md                   # This file! Describes the repository
└── renv.lock                   # Lists R version and all packages in the R environment
```

<br>

## ⏰ Run time and machine specification

The overall run time will vary depending on how the template model is used. A few example implementations are provided in `rmarkdown/` and the run times for these were:

* `analysis.Rmd`: 42s
* `choosing_parameters.Rmd`: 56s
* `generate_exp_results.Rmd`: 0s

<!--TODO: Check these are up to date -->

These times were obtained on an Intel Core i7-12700H with 32GB RAM running Ubuntu 24.04.1 Linux.

<br>

## 📝 Citation

<!-- TODO: Add Zenodo critation once archived -->

> Heather, A. (2025). Simple Reproducible R Discrete-Event Simulation (DES) Template. GitHub. https://github.com/pythonhealthdatascience/rap_template_r_des.

Researcher details:

| Contributor | ORCID | GitHub |
| --- | --- | --- |
| Amy Heather | [![ORCID: Heather](https://img.shields.io/badge/ORCID-0000--0002--6596--3479-brightgreen)](https://orcid.org/0000-0002-6596-3479) | https://github.com/amyheather |

<br>

## 📜 Licence

This template is licensed under the MIT License.

```
MIT License

Copyright (c) 2025 STARS Project Team

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

<br>

## 💰 Funding

This project was developed as part of the project STARS: Sharing Tools and Artefacts for Reproducible Simulations. It is supported by the Medical Research Council [grant number [MR/Z503915/1](https://gtr.ukri.org/projects?ref=MR%2FZ503915%2F1)].

<br>

## 📄 Template README for your project

Delete everything from this line and above, and use the following structure as the starting point for your project README:
___

<br>
<br>
<br>

<div align="center">

# Your Project Name

![python](https://img.shields.io/badge/-Python_Version-blue?logo=python&logoColor=white)
![licence](https://img.shields.io/badge/Licence-Name-green.svg?labelColor=gray)

</div>

## Description

Provide a concise description of your project.

<br>

## Installation

Provide instructions for installing dependencies and setting up the environment.

<br>

## How to run

Provide step-by-step instructions and examples.

Clearly indicate which files will create each figure in the paper. Hypothetical example:

* To generate **Figures 1 and 2**, execute `base_case.Rmd`
* To generate **Table 1** and **Figures 3 to 5**, execute `scenario_analysis.Rmd`

<br>

## Run time and machine specification

State the run time, and give the specification of the machine used (which achieved that run time).

**Example:** Intel Core i7-12700H with 32GB RAM running Ubuntu 24.04.1 Linux. 

To find this information:

* **Linux:** Run `neofetch` on the terminal and record your CPU, memory and operating system.
* **Windows:** Open "Task Manager" (Ctrl + Shift + Esc), go to the "Performance" tab, then select "CPU" and "Memory" for relevant information.
* **Mac:** Click the "Apple Menu", select "About This Mac", then window will display the details.

<br>

## Citation

Explain how to cite your project and include correct attribution for this template.
