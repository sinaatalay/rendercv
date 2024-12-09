# Frequently Asked Questions (FAQ)

## Can I add a profile picture?

### `moderncv`

There is a built-in command in the `moderncv` package.

    \photo A command for a photo. Takes the image file name as a required argument. Takes the height of the photo and the thickness of the photo frame as optional arguments.

        \photo[<photo height >][< frame thickness >]{<photo file name >}

You can add the line into the `Preamble.j2.tex` file that is in the `moderncv` folder after initializing (run ```rendercv new "Your Name"``` command first). Keep in mind that the root directory for outputs will be the `rendercv_output` folder (when running ```rendercv render Your_Name_CV.yaml``` command). So, for example, when you have your JPG in the folder where you have your `Your_Name_CV.yaml` file then you can add the picture path so (on Windows):
```
\photo[3cm][1pt]{<<"../MyCVphoto.jpg">>}
```

See more on the [user guide for `moderncv`](https://ctan.math.washington.edu/tex-archive/macros/latex/contrib/moderncv/manual/moderncv_userguide.pdf).

## Can I use JSON Resume schema?

Both RenderCV and JSON Resume follows their own schema so you cannot directly use JSON Resume schema but you can use this [jsonresume-to-rendercv](https://github.com/guruor/jsonresume-to-rendercv) converter to convert JSON Resume to RenderCV format.

## How to use with Docker?

A docker image is available on [Dockerhub](https://hub.docker.com/r/rendercv/rendercv). Here is how to use it:

1.  Run the command below to generate starting input files.

```sh
docker run -it -v <path-to-your-cv-directory>:/data rendercv/rendercv rendercv new "Full Name"
```

2.  Edit the contents of `Full_Name_CV.yaml` in your favorite editor (*tip: use an editor that supports JSON Schemas*).

3.  Run the command below to generate your CV.

```sh
docker run -it -v <path-to-your-cv-directory>:/data mathiasvda/rendercv rendercv render Full_name_CV.yaml
```