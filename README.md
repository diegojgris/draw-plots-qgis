# Draw field experiment plots using R scripts in QGIS

## Installation

In order to use these tools, you will need to first download and install the following software:
1. [QGIS](https://qgis.org/en/site/forusers/download.html)
2. [R](https://cran.r-project.org/mirrors.html)

Once they are installed, you can open QGIS and install the **Processing R Provider** plugin by going to:

> Plugins > Manage and Install Plugins... > All > Search for "Processing R Provider" > Install Plugin

![Installing Processing R Provider](img/install_r_plugin.png)

Then, download this repository by clicking on the green *Code* button:

> Code > Download ZIP

![Downloading GitHub repository](img/download_repo.png)

Unzip the downloaded folder and move it to a permanent location (any place from where it will not be moved or deleted).

Finally, go back to QGIS to adjust the following settings:

1. Find the Processing Toolbox pane, usually located on the right side of the screen. If you do not see it, go to:

> View > Panels > Processing Toolbox

and make sure it is enabled.

![Enabling the Processing Toolbox pane](img/view_processing_toolbox.png)

2. On the Processing Toolbox pane, click on the *Options* button, identified by a wrench icon. Then, go to:

> Providers > R

a) Check the box for *Use 64 bit version*

b) Double click on the editable field to the right side of *R scripts folder*, and then click on the [...] button that shows up at the end of this field. Click on the *Add* button on the new window that pops up and look for the **rscripts** folder inside the unzipped folder that you downloaded and placed in a permanent location. This will make sure that QGIS can find the R scripts and make them available in the Processing Toolbox.

![Adjusting the Processing R Provider settings](img/change_r_plugin_settings.png)

After doing this, you should be able to find the new tools in the Processing Toolbox pane under:

> R > Draw trial plots

![R scripts location in QGIS](img/r_scripts.png)

## Usage
