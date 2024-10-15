FROM registry.gitlab.com/pages/hugo/hugo_extended:0.128.0

RUN apk add --no-cache go curl bash npm
