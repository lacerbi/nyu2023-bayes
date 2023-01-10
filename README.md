# Bayesian model fitting made easy with Variational Bayesian Monte Carlo - (Py)VBMC

Tutorial on Bayesian model fitting using the (Py)VBMC package, presented at a workshop at the Center for Neural Science at New York University (January 2023).
The tutorial is available for both Python and MATLAB.

**Lecturer:** [Luigi Acerbi](https://www.helsinki.fi/en/researchgroups/machine-and-human-intelligence), [@AcerbiLuigi](https://twitter.com/AcerbiLuigi) (University of Helsinki).


## Instructions

To prepare for the tutorial, please ensure that you have (Py)VBMC installed **before the start of the tutorial session**.

### Python

- Install the [PyVBMC package](https://github.com/acerbilab/pyvbmc). You can follow the simple instructions [here](https://acerbilab.github.io/pyvbmc/installation.html).
- If you use the Anaconda Python distribution, you can use the following instructions to create a minimal working environment with Jupyter notebook:
```
conda create -pyvbmc-env python=3.9
conda activate pyvbmc-env
conda install --channel=conda-forge pyvbmc
conda install --channel=conda-forge jupyter
```

### MATLAB

- Download and install the [VBMC toolbox](https://github.com/acerbilab/vbmc). You can follow the simple instructions [here](https://github.com/acerbilab/vbmc#installation).

### Running the tutorial

- To run the tutorial, download / clone the repository locally. The tutorial is available both as a MATLAB script and as a Python Jupyter notebook.
- **The current tutorials in this repository are still work in progress. The finalized tutorials will be uploaded before the start of the session (and this note will be removed). Please download the finalized version just before the start of the session.**
- Tutorial slides will also be uploaded in this repository later.

![PyVBMC demo](vbmc_animation.gif)

### License

Unless stated otherwise, the material in this repo is released under the [MIT License](LICENSE).

