# prunedocker-crystal

This project supports the blog post [Why Crystal is Awesome](http://paulosuzart.github.io/blog/2018/02/15/why-crystal-is-awesome/)

## Installation

Just clone the repo then `shards update`.

## Usage

Build it with `shards build prunedocker --error-trace` and you get your binary under `bin` folder. Then run it:

`./bin/prunedocker -u someUser -p somepass -r some_repo -k 12 --dry-run`

Use the `-h` options to see the help menu like this one:

```
prunedocker OPTIONS

Options:
  --dry-run       Just lists tags that will be dropped without actually dropping them
  -k, --keep      Keeps k tags in the repo. Will delete the remaining older tags
  -p, --password  Dockerhub password
  -r, --repo      Dockerhub repository
  -u, --user      Dockerhub Login
  -h, --help      show this help
```

## Contributing

This is a simple port from a racket project produced for a blog post. Not sure if need any contribuition, but just in case:

1. Fork it ( https://github.com/[your-github-name]/prunedocker-crystal/fork )
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request

## Contributors

- [[your-github-name]](https://github.com/[your-github-name]) Paulo Suzart - creator, maintainer
