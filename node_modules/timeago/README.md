# timeago

A wrapper for Ryan McGeary's [jQuery plugin](http://timeago.yarp.com/).

![timeago](http://i.imgur.com/W1Zwy.png)

#install

    npm install timeago

#usage

````javascript
var timeago = require('timeago');

var pretty = timeago(+new Date());

console.log(pretty); // just now
````

You can also use it in Express app templates:

````javascript
var app = express.createServer();

app.helpers({
  timeago: require('timeago')
});
````

````ejs
<div class="timeago"><%- timeago(widget.created) %></div>
````
