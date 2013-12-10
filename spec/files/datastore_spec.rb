# -*- coding: utf-8 -*-

require 'spec_helper'

describe Dolphin::DataStore do

  before(:all) do
    @settings = Marshal.load(Marshal.dump(Dolphin.settings))
  end

  it 'expect to select mysql adapter' do
    Dolphin.settings['database']['adapter'] = 'mysql'
    Dolphin.settings['database']['host'] = '127.0.0.1'
    Dolphin.settings['database']['port'] = '3306'
    store = Dolphin::DataStore.current_store
    expect(store).to be_a(Dolphin::DataStore::Mysql)
  end

  it 'expect to select cassandra adapter' do
    Dolphin.settings['database']['adapter'] = 'cassandra'
    Dolphin.settings['database']['hosts'] = '127.0.0.1'
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
    Dolphin.settings.params = @settings.params
  end
end
