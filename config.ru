require 'rubygems'
require 'bundler'

require "bundler/setup"
require 'sinatra'
require 'json'
require 'openssl'
require 'base64'
require 'omniauth'
require 'omniauth-quickbooks'
require 'dotenv'
require 'qbo_api'
require 'pry'

Bundler.require

require './authnet.rb'

run AuthNetImporter
