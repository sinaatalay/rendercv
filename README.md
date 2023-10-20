# RenderCV
[![CI](https://github.com/sinaatalay/rendercv/actions/workflows/ci.yaml/badge.svg?branch=main)](https://github.com/sinaatalay/rendercv/actions/workflows/ci.yaml)
[![coverage](https://coverage-badge.samuelcolvin.workers.dev/sinaatalay/rendercv.svg)](https://coverage-badge.samuelcolvin.workers.dev/redirect/sinaatalay/rendercv)
[![pypi](https://img.shields.io/pypi/v/rendercv.svg)](https://pypi.python.org/pypi/rendercv)

A Python application that creates a $\LaTeX$ CV as a PDF from a JSON/YAML input file. Currently, it only supports one theme (classic), which can be seen [here](https://github.com/sinaatalay/rendercv/blob/main/John_Doe_CV.pdf?raw=true). More themes are planned to be supported in the future.

**What does it do?**
- It parses a YAML (or JSON) file that looks like this:
```yaml
cv:
  name: John Doe
  label: Mechanical Engineer
  location: Geneva, Switzerland
  email: johndoe@example.com
  phone: "+33749882538"
  website: https://example.com
  social_networks:
    - network: GitHub
      username: johndoe
  education:
    - institution: Boğaziçi University
      url: https://boun.edu.tr
      area: Mechanical Engineering
      study_type: BS
      location: Istanbul, Turkey
      start_date: "2017-09-01"
      end_date: "2023-01-01"
      transcript_url: https://example.com
      gpa: 3.10/4.00
      highlights:
        - "Class rank: 10 of 62"
    - institution: The University of Texas at Austin
      url: https://utexas.edu
      area: Mechanical Engineering, Student Exchange Program
      location: Austin, TX, USA
      start_date: "2021-08-01"
      end_date: "2022-01-15"
  work_experience:
    - company: AmIACompany
      position: Summer Intern
      location: Istanbul, Turkey
      url: https://example.com
      start_date: "2022-06-15"
      end_date: "2022-08-01"
      highlights:
        - AmIACompany is a technology company that provides web-based engineering applications
          that enable the simulation and optimization of products and manufacturing tools.
        - Modeled and simulated a metal-forming process deep drawing using finite element
          analysis with open-source software called CalculiX.
```
- It validates the input, such as checking if the dates are consistent, checking if the URLs are correct, warning if there are any spelling mistakes, etc.
- Then creates a $\LaTeX$ file.
- Then renders the $\LaTeX$ file to generate the PDF, and you don't need $\LaTeX$ installed on your PC because the packages come with [TinyTeX](https://yihui.org/tinytex/).
