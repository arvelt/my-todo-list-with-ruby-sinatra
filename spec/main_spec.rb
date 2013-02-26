# coding: utf-8
require './main'
require "./models/todo"
require 'spec_helper'

describe 'Todolistのテスト' do

  context 'Todoが空の時' do

    it '問題ないこと' do
      get '/'
      last_response.should be_ok
    end

    it 'Todoを追加できること' do
      @message = "テストメッセージ"
      get '/'
      last_response.should be_ok

      post '/add' , :send_content=>@message
      last_response.should be_ok

      get '/'
      last_response.body.should include(@message)
    end
  end
end