<h3 align="center">
  <a href="https://github.com/fastlane/fastlane">
    <img src="app/assets/images/fastlane.png" width="150" />
    <br />
    fastlane
  </a>
</h3>
<p align="center">
  <a href="https://github.com/fastlane/deliver">deliver</a> &bull; 
  <a href="https://github.com/fastlane/snapshot">snapshot</a> &bull; 
  <a href="https://github.com/fastlane/frameit">frameit</a> &bull; 
  <a href="https://github.com/fastlane/pem">PEM</a> &bull; 
  <a href="https://github.com/fastlane/sigh">sigh</a> &bull; 
  <a href="https://github.com/fastlane/produce">produce</a> &bull;
  <a href="https://github.com/fastlane/cert">cert</a> &bull;
  <a href="https://github.com/fastlane/codes">codes</a> &bull;
  <a href="https://github.com/fastlane/pilot">pilot</a>
</p>
-------

enhancer
============

[![Twitter: @KauseFx](https://img.shields.io/badge/contact-@FastlaneTools-blue.svg?style=flat)](https://twitter.com/FastlaneTools)
[![License](http://img.shields.io/badge/license-MIT-green.svg?style=flat)](https://github.com/fastlane/enhancer/blob/master/LICENSE)

[fastlane](https://fastlane.tools) tracks the number of errors for each action to detect integration issues.

### Privacy

This does **not** store any personal or sensitive data. Everything `enhancer` stores is the ratio between successful and failed action runs.

### Why?

- This data is very useful to find out which actions tend to cause the most build errors and improve them! 
- The actions that are used by many developers should be improved in both implementation and documentation. It's great to know which actions are worth improving!

To sum up, all data is used to improve `fastlane` more efficiently

### Opt out

You can set the environment variable `FASTLANE_OPT_OUT_USAGE` to opt out.

Alternatively, add `opt_out_usage` to your `Fastfile`.

# License
This project is licensed under the terms of the MIT license. See the LICENSE file.
