# coding: utf-8
require './main'
require "./models/todo"
require 'spec_helper'

describe 'Todolistのテスト' do

  context 'ログインしていない時' do

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
    end

    it "Todoを削除できること" do
      message = "テストメッセージ６"
      due_date = due_date = "2013-01-01 22:00"

      get '/'
      todo = Todo.new(:content=>message,
                      :user_id=>session[:session_id],
                      :status=>0,
                      :due_date=>due_date).save

      post '/delete' 
      last_response.body.should_not include(todo[:id].to_s)
    end
  end
  
  context 'ログインしている時' do
    #TODO
  end

end