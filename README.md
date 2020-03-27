# *MAX* – Museum Analytics

![](www/images/max_wallpaper_en.png)


## Overview

In recent years, large museum databases have been created in the international museum sector that are awaiting meaningful use. They offer a hitherto unknown opportunity for empirical investigation of the history of collections, which can be expected to yield far-reaching results, especially in a comparative perspective. *Museum Analytics*, *MAX*, is intended to enable lecturers to import freely selectable museum databases and make them available to students for analysis.


## Functionalities

* A graphical user interface that enables fast progress without excessive training. It is realized with the open-source programming language *R* and the *Shiny* web framework, which are *state of the art* due to their continuous development.
* An import module to “pull” existing data, e.g., from the [Rijksmuseum](https://www.rijksmuseum.nl/), into the tool as easily as possible. Own data sets can be fed in just as easily. Currently supported are `.rds`, `.txt`, `.csv`, `.json`, `.xls`, and `.xlsx` files.
* An export module to extract the processed, cleansed, and visualized data as a `.zip` file with `R`-compatible `.rds` files. Reproducible *R* code can also be generated based on the defined tasks.
* Dynamic and interactive graphics with *Plotly*, which show more details on mouseover, e.g., the title or artist of an artwork. They enrich the statistical analysis by displaying complex relationships in an attractive way. Plot subregions can be zoomed in.


## Extensions

If you want to extend the functionality of *MAX*, you can add an *R* package function to the `.yaml` file in the folder `data` that corresponds to the respective section, i.e., currently either `preprocess-history.yaml` or `visualize-history.yaml`. The function to be added must be *Pipe*-friendly.


## About the Project

*MAX* was funded from 1 March to 30 November 2018 within the program *Lehre@LMU* to strengthen research orientation in teaching. It is a project of the *IT-Gruppe Geisteswissenschaften*, the Institute of Statistics and the Institute of Art History at *Ludwig-Maximilians-Universität München*. Our team consists of Severin Burg, B.A., [Prof. Dr. Hubertus Kohle](https://www.kunstgeschichte.uni-muenchen.de/personen/professoren_innen/kohle/index.html), [Prof. Dr. Helmut Küchenhoff](https://www.stablab.stat.uni-muenchen.de/personen/leitung/kuechenhoff1/index.html) and [Stefanie Schneider, M.Sc.](https://www.kunstgeschichte.uni-muenchen.de/personen/wiss_ma/schneider/index.html)

The web application is written using *R* and the *Shiny* web framework. It is open source and licensed under *GNU General Public License v3.0*. This version is a complete re-implementation that makes use of *Shiny* modules and custom HTML templates. For the previous version, please see: https://dhvlab.gwi.uni-muenchen.de/max/.


## References

* Schneider, Stefanie (2020): „Museum Analytics. Museale Sammlungen neu und anders entdecken“. In: Museumskunde 85 (*upcoming*).
* Schneider, Stefanie; Kohle, Hubertus; Burg, Severin; Küchenhoff, Helmut (2019): „Museum Analytics. Ein Online-Tool zur vergleichenden Analyse musealer Datenbestände“. Postersession bei der DHd 2019. Digital Humanities: multimedial & multimodal, DOI: https://doi.org/10.5281/zenodo.2612834.
* Schneider, Stefanie; Kohle, Hubertus; Burg, Severin; Küchenhoff, Helmut (2019): „Museum Analytics. Ein Online-Tool zur vergleichenden Analyse musealer Datenbestände“. In: DHd 2019. Digital Humanities: multimedial & multimodal. Konferenzabstracts, S. 334–335, DOI: https://doi.org/10.5281/zenodo.2596095.


## Contributing

Please report issues, feature requests, and questions to the [GitHub issue tracker](https://github.com/stefanieschneider/MAX/issues). We
have a [Contributor Code of Conduct](https://github.com/stefanieschneider/MAX/blob/master/CODE_OF_CONDUCT.md). By participating in *MAX* you agree to abide by its terms.
