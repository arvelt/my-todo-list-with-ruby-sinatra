# encoding: utf-8
require './main'
require "./models/todo"
require 'spec_helper'
require 'json'

describe 'Todolistのテスト' do

  context 'ログインしていない時' do

    it 'ユーザーIDがセッションIDであること' do
      get '/'
      last_request.env['rack.session'][:user_id].should == session[:session_id]
    end

    it 'トップページにアクセスし、問題ないこと' do
      get '/'
      last_response.should be_ok
    end

    it 'Todoを追加できること' do
      message = "テストメッセージ１"
      due_date = "2013-01-01 22:00"

      get '/'
      last_response.should be_ok

      post '/add' , :send_content=>message , :send_duedatetime=>due_date
      last_response.should be_ok

      get '/'
      last_response.body.should include(message)
    end

    it "Todoを追加するとき、日付がyyyy-MM-dd hh:mm以外だとエラーとなること" do

      message = "テストメッセージ２"
      due_date = "20130101 2200"
      err_msg = "その日時を指定することはできません"

      get '/'
      last_response.should be_ok

      post '/add' , :send_content=>message , :send_duedatetime=>due_date
      last_response.should be_ok
      last_response.body.should include(err_msg)
    end

    it 'Todoを更新できること' do
      befor_message = "テストメッセージ４"
      after_message = "テストメッセージ４を修正"
      due_date = "2013-01-01 22:00"

      get '/'
      todo = Todo.new(:content=>befor_message,
                      :user_id=>session[:session_id],
                      :status=>0,
                      :due_date=>due_date).save

      post '/update' , :key=>todo[:id] ,:content=>after_message
      last_response.body.should include(after_message)

      Todo.where(:id=>todo[:id]).delete if Todo.get{count(:id)} > 0
    end

    it "Todoを更新するとき、日付のyyyy-MM-dd hh:mm以外がエラーとなること" do
      befor_message = "テストメッセージ５"
      after_message = "テストメッセージ５"
      due_date = "20130101 2200"
      err_msg = "その日時を指定することはできません"

      get '/'
      todo = Todo.new(:content=>befor_message,
      :user_id=>session[:session_id],
      :status=>0,
      :due_date=>due_date).save

      post '/update' , :key=>todo[:id] ,:content=>after_message , :due_date=>due_date
      last_response.body.should include(err_msg)

      Todo.where(:id=>todo[:id]).delete if Todo.get{count(:id)} > 0
    end

    it "Todoを削除できること" do
      message = "テストメッセージ６"
      due_date = due_date = "2013-01-01 22:00"

      get '/'
      todo = Todo.new(:content=>message,
                      :user_id=>session[:session_id],
                      :status=>0,
                      :due_date=>due_date).save

      post '/delete' , :key=>todo[:id]
      last_response.body.should_not include(todo[:id].to_s)

      Todo.where(:id=>todo[:id]).delete if Todo.get{count(:id)} > 0
    end
  end

  context 'ログインしている時' do

    it 'ユーザーIDが認証されたIDであること' do
      get '/'
      get '/auth/google_oauth2'
      follow_redirect!
      session[:user_id].should == last_request.env["omniauth.auth"]['uid']
    end
  end
end

describe 'Todolist APIのテスト' do

  it 'データなし' do
    post '/api/list'
    last_response.should be_ok

    json = JSON.parse(last_response.body)
    json.size.should eq(0)
  end

  it 'TODOの一覧が取得できること' do

    message = "テストメッセージ１０"
    due_date = "2013-02-03 19:23"

    get  '/' #session_idのため
    todo = Todo.new(:content=>message,
                    :user_id=>session[:session_id],
                    :status=>0,
                    :due_date=>due_date).save

    post '/api/list' , :user_id=>session[:session_id]
    last_response.should be_ok

    json = JSON.parse(last_response.body)
    json.size.should eq(1)
    json[0]["user_id"].should eq(session[:session_id])
    json[0]["content"].should eq(message)
    json[0]["due_date"].should eq(due_date)

    Todo[todo.id].delete unless Todo[:id]==todo.id
  end

  it 'TODOが追加できること' do
    message = "テストメッセージ１１"
    due_date = "2013-01-02 23:10"

    get  '/' #session_idのため 要改修
    post '/api/add' , :send_content=>message , :send_duedatetime=>due_date
    last_response.should be_ok

    json = JSON.parse(last_response.body)
    json.size.should_not eq(0)
    json[0]["user_id"].should eq(session[:session_id])
    json[0]["content"].should eq(message)
    json[0]["due_date"].should eq(due_date)

  end

  it "Todoを追加するとき、日付がyyyy-MM-dd hh:mm以外だとエラーとなること" do
      message = "テストメッセージ１５"
      due_date = "20130101 2200"
      err_msg = "その日時を指定することはできません"

    get  '/' #session_idのため 要改修
    post '/api/add' , :send_content=>message , :send_duedatetime=>due_date
    last_response.should be_ok

    json = JSON.parse(last_response.body)
    json.size.should_not eq(0)
    json[0]["err"].should eq(err_msg)
  end

  it 'TODOが更新できること' do
    befor_message = "テストメッセージ１２"
    after_message = "テストメッセージ１２を修正"
    due_date = "2013-02-03 20:20"

    get  '/' #session_idのため 要改修
    todo = Todo.new(:content=>befor_message,
                    :user_id=>session[:session_id],
                    :status=>0,
                    :due_date=>due_date).save

    post '/api/update' , :key=>todo[:id] ,:content=>after_message , :due_date=>due_date
    last_response.should be_ok

    json = JSON.parse(last_response.body)
    json.size.should_not eq(0)
    json[0]["user_id"].should eq(session[:session_id])
    json[0]["content"].should eq(after_message)
    json[0]["due_date"].should eq(due_date)

    Todo[todo.id].delete unless Todo[:id]==todo.id
  end

  it "Todoを更新するとき、日付がyyyy-MM-dd hh:mm以外だとエラーとなること" do
    befor_message = "テストメッセージ１２"
    after_message = "テストメッセージ１２を修正"
    due_date = "20130221 2200"
    err_msg = "その日時を指定することはできません"

    get  '/' #session_idのため 要改修
    todo = Todo.new(:content=>befor_message,
                    :user_id=>session[:session_id],
                    :status=>0,
                    :due_date=>due_date).save

    post '/api/update' , :key=>todo[:id] ,:content=>after_message , :due_date=>due_date
    last_response.should be_ok

    json = JSON.parse(last_response.body)
    json.size.should_not eq(0)
    json[0]["err"].should eq(err_msg)

    Todo[todo.id].delete unless Todo[:id]==todo.id
  end

  it "Todoを削除できること" do
    message = "テストメッセージ１３"
    due_date = "2013-02-24 22:01"

    get  '/' #session_idのため 要改修
    todo = Todo.new(:content=>message,
                    :user_id=>session[:session_id],
                    :status=>0,
                    :due_date=>due_date).save

    post '/api/delete' , :key=>todo[:id]
    last_response.should be_ok

    json = JSON.parse(last_response.body)
    json.size.should eq(0)
    json[0].should == nil

    Todo.where(:id=>todo[:id]).delete if Todo.get{count(:id)} > 0
  end
end
