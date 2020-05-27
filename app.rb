# app.rb
#!/usr/bin/env ruby
require 'rubygems'
require 'sinatra'
require 'dm-core'
require 'dm-migrations'

DataMapper.setup(:default, "sqlite3://#{Dir.pwd}/users.db")

class User
  include DataMapper::Resource
  property :id, Serial
  property :username, String
  property :password, String
  property :totalWin, Integer
  property :totalLost, Integer
  property :totalProfit, Integer
end

DataMapper.finalize

class HelloWorldApp < Sinatra::Base

  configure do
    enable :sessions     # set :sessions, true
    set :won, 0
    set :lost, 0
    set :profit, 0
  end

  get '/' do
    redirect '/login'
  end

  get '/character-sheet' do
    session[:charisma]=3
    erb :test
  end

  get '/login' do
    if session[:login]
      redirect '/gambling'
    else
      erb :app
    end
  end

  get'/gambling' do
    if session[:login]
      user=User.first username: session[:name]
      session[:dbLost]=user.totalLost
      session[:dbWin]=user.totalWin
      session[:dbProfit]=user.totalProfit
      erb :gamble
    else
      redirect '/login'
    end
  end

  post '/bet' do
  stake = params[:bet].to_i
  number = params[:number].to_i
  roll = rand(6) + 1
    if number == roll
      save_session(:won, 10*stake)
      session[:message]="The dice landed on #{roll}. You won $#{stake*10}."
    else
      save_session(:lost, stake)
      session[:message]="The dice landed on #{roll}. You lost $#{stake}."
    end
    redirect '/gambling'
  end

  def save_session(won_lost, money)
    count = (session[won_lost] || 0).to_i
    count += money
    session[won_lost] = count
    session[:profit]=session[:won].to_i-session[:lost].to_i
  end

  post '/login' do
    pass=params[:password].to_s
    use=params[:username].to_s
    user=User.first username: use
    if user==nil #username not registered, will cause query crash
      session[:message] = "Your login was not valid. Please try again."
      redirect '/login'
    end
    if pass==user.password #valid password
      session[:login] = true
      session[:name] = params[:username].to_s
      session[:message] = nil
      session[:won] = 0
      session[:lost] = 0
      session[:profit]= 0
      redirect '/gambling'
    else #invalide password
      session[:message] = "Your login was not valid. Please try again."
      redirect '/login'
    end
  end

  post '/logout' do
    user=User.first username: session[:name]
    user.totalLost+=session[:lost]
    user.totalWin+=session[:won]
    user.totalProfit+=session[:profit]
    user.save
    session[:login]=false
    session[:name] = nil
    redirect '/login'
  end

  get '/hello' do
    erb:test
  end

  post '/food' do
    "My name is #{params[:name]}, and I love #{params[:favorite_food]}."
  end

    not_found do
      "This page does not exist."
    end
end
