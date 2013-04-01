# encoding: utf-8
# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/rpm/blob/master/LICENSE for complete details.

require File.expand_path(File.join(File.dirname(__FILE__),'..','..','test_helper'))
require 'new_relic/agent/autostart'

class AutostartTest < Test::Unit::TestCase

  def test_typically_the_agent_should_autostart
    assert ::NewRelic::Agent::Autostart.agent_should_start?
  end

  def test_agent_wont_autostart_if_IRB_constant_is_defined
    assert !defined?(::IRB), "precondition: IRB shouldn't b defined"
    Object.const_set(:IRB, true)
    assert ! ::NewRelic::Agent::Autostart.agent_should_start?, "Agent shouldn't autostart in IRB session"
  ensure
    Object.send(:remove_const, :IRB)
  end

  def test_agent_wont_autostart_if_top_level_rake_task_is_assets_precompile
    Rake.stubs(:application => stub(:top_level_tasks => ['assets:precompile']))
    assert ! ::NewRelic::Agent::Autostart.agent_should_start?, "Agent shouldn't during assets compilation"
  end


  MyConst = true
  def test_blacklisted_constants_can_be_configured
    with_config('autostart.blacklisted_constants' => "IRB,::AutostartTest::MyConst") do
      assert ! ::NewRelic::Agent::Autostart.agent_should_start?, "Agent shouldn't autostart when environment contains blacklisted constant"
    end
  end

  def test_blacklisted_executable_can_be_configured
    @orig_dollar_0, $0 = $0, '/foo/bar/baz'
    with_config('autostart.blacklisted_executables' => 'boo,baz') do
      assert ! ::NewRelic::Agent::Autostart.agent_should_start?, "Agent shouldn't autostart when process is invoked by blacklisted executable"
    end
  ensure
    $0 = @orig_dollar_0
  end

  def test_blacklisted_rake_tasks_can_be_configured
    with_config('autostart.blacklisted_rake_tasks' => 'foo,bar,baz:bang') do
      Rake.stubs(:application => stub(:top_level_tasks => ['biz', 'baz:bang']))
      assert ! ::NewRelic::Agent::Autostart.agent_should_start?, "Agent shouldn't during blacklisted rake task"
    end
  end
end
