# coding: utf-8
require 'sinatra'
require "sinatra/reloader" if development?
require 'Sequel'
require "omniauth"
require "omniauth-google-oauth2"
require "./models/todo"
require 'slim'
Slim::Engine.default_options[:pretty] = true  #出力htmlを整形する設定  true=>する,false=>しない

#環境設定
#set :environment, :production
set :environment, :development
 
# Sinatra のセッションを有効にする
enable :sessions
  
# OmniAuth の設定
use OmniAuth::Builder do
  # Twitter の OAuth を使う
  provider :google_oauth2, ENV['GOOGLE_ID'], ENV['GOOGLE_SECRET']
end

# 開発環境の場合はテストモックを使用
configure :development do
  OmniAuth.config.test_mode = true
  OmniAuth.config.mock_auth[:google_oauth2] = {
    "provider" => "google",
    "uid" => 4580841,
    "info" => {
      "name" => "Arvelt S",
    },
  }
end

get "/auth/:provider/callback" do
  # 認証情報は request.env に格納されている
  @oauth = request.env["omniauth.auth"]
  session[:user_id] = @oauth['uid']
    
  @todos = Todo.all
  slim :index
end

get '/logout' do
  session.delete("omniauth.auth".to_sym)
  redirect '/'
end

get '/' do
  
  #Commentsテーブルから結果セットを取得してビューへ渡す

  @todos = Todo.all
  p "test"
  p @todos
  slim :index
end

post '/add' do
  
  p params[:send_content]
  p params[:send_duedatetime]

  user_id = session[:user_id]
  due_date = params[:send_duedatetime]
  
  @err = nil

  #due_dateがtimeなので、空文字いれてしまうとストリングフォーマットしようとして落ちる
  if due_date == "" then
    due_date = nil
  else
    
    #入力があればフォーマットチェック
    begin
      Date.strptime(due_date, "%Y-%m-%d %H:%M")
    rescue 
      @err = "その日時を指定することはできません"
    end
  end
    
  if @err.nil?
    #取得したパラメーターを元にtodoモデルを作成
    @todo = Todo.new()
    @todo.user_id = user_id
    @todo.status = "1"
    @todo.content = params[:send_content].to_s
    @todo.due_date = due_date
    @todo.save
  end
  
  #全てのtodoを取得して返す
  @todos = Todo.all
  slim :list
end

post '/delete' do
  
  p params[:key]
  key = params[:key]
    
  #取得したパラメーターを元にtodoモデルを作成
  @todo = Todo[:id=>key]
  @todo.destroy
  
  #全てのtodoを取得して返す
  @todos = Todo.all
  slim :list
end

post '/update' do
  
  p params[:key]
  p params[:status]
  p params[:content]
  p params[:due_date]

  #パラメタ取得
  key =  params[:key]
  status =  params[:status]
  content = params[:content]
  due_date = params[:due_date]

  @err = nil

  #due_dateがtimeなので、空文字いれてしまうとストリングフォーマットしようとして落ちる
  if due_date == "" then
    due_date = nil
  else
    
    #入力があればフォーマットチェック
    begin
      Date.strptime(due_date, "%Y-%m-%d %H:%M")
    rescue 
      @err = "その日時を指定することはできません"
    end
  end
    
  p @err
  
  if @err.nil?
    #主キーでモデルを取得し、更新して保存
    @todo = Todo[:id=>key]
    @todo.update(
      :status => status,
      :content => content,
      :due_date => due_date
    )
    @todo.save
  end
    
  
  #全てのtodoを取得して返す
  @todos = Todo.all
  slim :list
end