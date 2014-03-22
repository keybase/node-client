// Generated by IcedCoffeeScript 1.7.1-b
(function() {
  var ArgumentParser, Base, Command, E, PackageJson, User, add_option_dict, env, format_fingerprint, iced, log, make_esc, req, session, util, __iced_k, __iced_k_noop,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  iced = require('iced-coffee-script').iced;
  __iced_k = __iced_k_noop = function() {};

  Base = require('./base').Base;

  log = require('../log');

  ArgumentParser = require('argparse').ArgumentParser;

  add_option_dict = require('./argparse').add_option_dict;

  PackageJson = require('../package').PackageJson;

  session = require('../session').session;

  make_esc = require('iced-error').make_esc;

  env = require('../env').env;

  log = require('../log');

  User = require('../user').User;

  format_fingerprint = require('pgp-utils').util.format_fingerprint;

  util = require('util');

  E = require('../err').E;

  req = require('../req');

  exports.Command = Command = (function(_super) {
    __extends(Command, _super);

    function Command() {
      return Command.__super__.constructor.apply(this, arguments);
    }

    Command.prototype.OPTS = {
      v: {
        alias: 'verbose',
        action: 'storeTrue',
        help: 'a full dump, with more gory details'
      },
      j: {
        alias: 'json',
        action: 'storeTrue',
        help: 'output in json format; default is simple text list'
      }
    };

    Command.prototype.use_session = function() {
      return false;
    };

    Command.prototype.needs_configuration = function() {
      return false;
    };

    Command.prototype.add_subcommand_parser = function(scp) {
      var name, opts, sub;
      opts = {
        help: "search all users",
        aliases: []
      };
      name = "search";
      sub = scp.addParser(name, opts);
      sub.addArgument(["query"], {
        nargs: 1,
        help: "a substring to find"
      });
      add_option_dict(sub, this.OPTS);
      return [name].concat(opts.aliases);
    };

    Command.prototype.search = function(cb) {
      var args, body, err, ___iced_passed_deferral, __iced_deferrals, __iced_k;
      __iced_k = __iced_k_noop;
      ___iced_passed_deferral = iced.findDeferral(arguments);
      args = {
        endpoint: "user/autocomplete",
        args: {
          q: this.argv.query[0]
        }
      };
      (function(_this) {
        return (function(__iced_k) {
          __iced_deferrals = new iced.Deferrals(__iced_k, {
            parent: ___iced_passed_deferral,
            filename: "/Users/max/src/keybase/node-client/src/command/search.iced",
            funcname: "Command.search"
          });
          req.get(args, __iced_deferrals.defer({
            assign_fn: (function() {
              return function() {
                err = arguments[0];
                return body = arguments[1];
              };
            })(),
            lineno: 58
          }));
          __iced_deferrals._fulfill();
        });
      })(this)((function(_this) {
        return function() {
          return cb(err, body);
        };
      })(this));
    };

    Command.prototype.run = function(cb) {
      var esc, list, ___iced_passed_deferral, __iced_deferrals, __iced_k;
      __iced_k = __iced_k_noop;
      ___iced_passed_deferral = iced.findDeferral(arguments);
      esc = make_esc(cb, "Command::run");
      (function(_this) {
        return (function(__iced_k) {
          __iced_deferrals = new iced.Deferrals(__iced_k, {
            parent: ___iced_passed_deferral,
            filename: "/Users/max/src/keybase/node-client/src/command/search.iced",
            funcname: "Command.run"
          });
          _this.search(esc(__iced_deferrals.defer({
            assign_fn: (function() {
              return function() {
                return list = arguments[0];
              };
            })(),
            lineno: 65
          })));
          __iced_deferrals._fulfill();
        });
      })(this)((function(_this) {
        return function() {
          console.log(JSON.stringify(list, null, "  "));
          return cb(null);
        };
      })(this));
    };

    return Command;

  })(Base);

}).call(this);