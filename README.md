# Locally run the site for development purposes

Ensure you have the `hugo/andrelousamarques:v1` docker image built using

> make build

And then launch the site locally with

> make run

Docker will mount the `andrelousamarques` folder as a volume and serve the site at `localhost:1313`

# Update theme

```
make sh

cd andrelousamarques

hugo mod get -u github.com/CaiJimmy/hugo-theme-stack/v3
```

# How this site was bootstraped

This section is for context on how this website was bootstrapped.

> make build

On an empty directory, run:

> make sh

A docker container shell will open at the current host folder. In there run:

```
# Create a new Hugo site (on a new folder named after the site)
# Note regarding gitlab (no longer applicable): the `before_script` target of the gitlab_ci pipeline must ensure that the working directory is the created "andrelousamarques" directory otherwise it wont deploy the page
hugo new site andrelousamarques

# Since we will install the theme as a hugo module, the `mod init` command should be run on an empty directory
hugo mod init gitlab.com/gzhsuol/andrelousamarques

# Download the hugo theme module
hugo mod get github.com/CaiJimmy/hugo-theme-stack/v3
```

And add the content as needed.

# Modified theme files

The following files included in this repository (under the `andrelousamarques` folder) are modified versions of the originals (at the same repository location) of the HUGO theme which sources are located at https://github.com/CaiJimmy/hugo-theme-stack/:

* assets/scss/general.scss
* assets/scss/partials/article.scss
* assets/scss/variables.scss
* layouts/partials/article/components/details.html
* layouts/partials/article-list/compact.html
* layouts/partials/article-list/default.html
* layouts/partials/data/title.html
* layouts/partials/footer/components/custom-font.html

The modified files will override the equivalent original files in the theme sources as per the theme documentation at https://stack.jimmycai.com/guide/modify-theme.

Each modification in labeled with a comment stating `GZHSUOL` (a.k.a.: me) on top of each modified line.

# License

## Articles

Files inside `andrelousamarques/content/posts` are licensed under (CC BY-NC-SA 4.0)[https://creativecommons.org/licenses/by-nc-sa/4.0/].

## Images and Documents

Files inside `andrelousamarques/static` are copyrighted to André Lousa Marques. All rights reserved.

## Icons

All the files inside the `andrelousamarques/assets/icons` directory are copyrighted to their respective companies.

## Software and other files not covered by the above

Files not mentioned in the previous paragraphs are licensed under the GNU General Public License v3.0.

Refer to the `LICENSE` file.
