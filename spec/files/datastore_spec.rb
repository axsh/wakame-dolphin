# -*- coding: utf-8 -*-

require 'spec_helper'

describe Dolphin::DataStore do

  before(:all) do
    @adapter = Dolphin.settings['database']['adapter']
  end

  it 'expect to select mysql adapter' do
    Dolphin.settings['database']['adapter'] = 'mysql'
    store = Dolphin::DataStore.current_store
    expect(store).to be_a(Dolphin::DataStore::Mysql)
  end

  it 'expect to select cassandra adapter' do
    Dolphin.settings['database']['adapter'] = 'cassandra'
    store = Dolphin::DataStore.current_store
    expect(store).to be_a(Dolphin::DataStore::Cassandra)
  end

  it 'expect to raise error if not exists adapter' do
    Dolphin.settings['database']['adapter'] = 'hoge'
    expect{Dolphin::DataStore.current_store}.to raise_error(NotImplementedError)
  end

  it 'exepct to raise error if not empty adapter' do
    Dolphin.settings['database']['adapter'] = nil
    expect{Dolphin::DataStore.current_store}.to raise_error(RuntimeError, 'Unknown database')

    Dolphin.settings['database']['adapter'] = ''
    expect{Dolphin::DataStore.current_store}.to raise_error(RuntimeError, 'Unknown database')
  end

  after(:all) do
    Dolphin.settings['database']['adapter'] = @adapter
  end

end
