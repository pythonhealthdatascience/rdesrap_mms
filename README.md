<div align="center">

# Simple Reproducible R<br>Discrete-Event Simulation (DES) Template

![r](https://img.shields.io/badge/-R-276DC2?logo=r&logoColor=white) <!--TODO Specify R version -->
![licence](https://img.shields.io/badge/Licence-MIT-green.svg?labelColor=gray)
<!-- TODO: Add DOI -->
<!-- TODO: Add CI tests badge -->

A simple template for creating DES models in R, within a **reproducible analytical pipeline (RAP)** <br>
Click on <kbd>Use this template</kbd> to initialise new repository.<br>
A `README` template is provided at the **end of this file**.

</div>

<br>

<!--
roxygen2::roxygenise()
devtools::check()
-->

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

TBC <!-- TODO: Finish writing introduction -->

<!-- TODO: Explain that structuring as package (as required by RAP) is beneficial in forcing you to keep model and analysis seperate, and so easily reuse that model in another analysis as all seperate, and as can use roxygen tools to ensure documentation is complete... devtools::check() to make sure files like DESCRIPTION are valid -->

<!-- 

#' Provides option of parallel processing, implemented using parLapply (as
#' mcLapply does not work on Windows and future_lapply would often get stuck).
#'# TODO: Test that random seeds are working properly
# e.g. consistent results, but unique between replications

# TODO: Check validity of approach to seeds...
# https://www.r-bloggers.com/2020/09/future-1-19-1-making-sure-proper-random-numbers-are-produced-in-parallel-processing/)

# TODO: Add methods that will get patient-level, trial-level and overall
# results tables

# TODO: Look at lots of examples of simmer models, for how people typically
# layout the model code (inc. the simmer documentation itself)

# TODO: Set up package, with validity checks, and Roxygen

# TODO: Look at how R scripts should be organised e.g. seperate scripts for
# seperate functions?

-->

## 🧐 What are we modelling?

A **simulation** is a computer model that mimics a real-world system. It allows us to test different scenarios and see how the system behaves. One of the most common simulation types in healthcare is **DES**.

In DES models, time progresses only when **specific events** happen (e.g., a patient arriving or finishing treatment). Unlike a continuous system where time flows smoothly, DES jumps forward in steps between events. For example, when people (or tasks) arrive, wait for service, get served, and then leave.

![Simple DES Animation](inst/assets/simple_des.gif)
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

TBC <!-- TODO: Finish writing instructions -->

<br>

## ❓ How does the model work?

TBC <!-- TODO: Write this section -->

<br>

## 📂 Repository structure

TBC <!-- TODO: Write this section -->

<br>

## ⏰ Run time and machine specification

TBC <!-- TODO: Write this section -->

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

Copyright (c) 2024 STARS Project Team

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
