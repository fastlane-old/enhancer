<h3 align="center">
  <a href="https://github.com/KrauseFx/fastlane">
    <img src="app/assets/images/fastlane.png" width="150" />
    <br />
    fastlane
  </a>
</h3>
<p align="center">
  <a href="https://github.com/KrauseFx/deliver">deliver</a> &bull; 
  <a href="https://github.com/KrauseFx/snapshot">snapshot</a> &bull; 
  <a href="https://github.com/KrauseFx/frameit">frameit</a> &bull; 
  <a href="https://github.com/KrauseFx/pem">PEM</a> &bull; 
  <a href="https://github.com/KrauseFx/sigh">sigh</a> &bull; 
  <a href="https://github.com/KrauseFx/produce">produce</a> &bull;
  <a href="https://github.com/KrauseFx/cert">cert</a> &bull;
  <a href="https://github.com/KrauseFx/codes">codes</a>
</p>
-------

enhancer
============

[![Twitter: @KauseFx](https://img.shields.io/badge/contact-@KrauseFx-blue.svg?style=flat)](https://twitter.com/KrauseFx)
[![License](http://img.shields.io/badge/license-MIT-green.svg?style=flat)](https://github.com/fastlane/enhancer/blob/master/LICENSE)

`enhancer` runs on [Heroku](https://www.heroku.com/). The [fastlane](https://fastlane.tools) track the number of failed actions to monitor the actions that don't work as reliable as expected.

### Privacy

This does **not** store any personal or sensitive data! All `enhancer` stores is the ratio between successful and failed action runs.

### Why?

- This is very useful to find out which actions tend to cause the most build errors and improve them! I'm sure 20% of the actions account for 80% of the crashes! It's helpful to know which ones to work on.
- The actions that are used by many developers should be improved in both implementation and documentation. It's great to know which actions are worth improving!

To sum up, all data is used to improve `fastlane` more efficiently

### Opt out

You can just set the environment variable `FASTLANE_OPT_OUT_USAGE` to opt out.

Alternatively, add `opt_out_usage` to your `Fastfile`.

### Data

All data is publicly available: [https://enhancer.fastlane.tools/](https://enhancer.fastlane.tools/).

# License
This project is licensed under the terms of the MIT license. See the LICENSE file.
