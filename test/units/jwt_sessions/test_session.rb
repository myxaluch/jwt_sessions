# frozen_string_literal: true

require 'minitest/autorun'
require 'jwt_sessions'

class TestSession < Minitest::Test
  attr_accessor :session, :payload, :tokens
  EXPECTED_KEYS = [:access, :csrf, :refresh].freeze

  def setup
    JWTSessions.encryption_key = '65994c7b523a3232e7aba54d8cbf'
    @payload = { test: 'test' }
    @session = JWTSessions::Session.new(payload)
    @tokens = session.login
  end

  def test_login
    decoded_access = JWTSessions::Token.decode(tokens[:access]).first
    assert_equal EXPECTED_KEYS, tokens.keys.sort
    assert_equal payload[:test], decoded_access['test']
  end

  def test_refresh
    refreshed_tokens = session.refresh(tokens[:refresh])
    decoded_access = JWTSessions::Token.decode(refreshed_tokens[:access]).first
    assert_equal EXPECTED_KEYS, refreshed_tokens.keys.sort
    assert_equal payload[:test], decoded_access['test']
  end

  def test_refresh_with_block
    assert_raises JWTSessions::Errors::Unauthorized do
      session.refresh(tokens[:refresh]) do
        raise JWTSessions::Errors::Unauthorized
      end
    end
    JWTSessions.exp_time = 0
    refreshed_tokens = session.refresh(tokens[:refresh]) do
      raise JWTSessions::Errors::Unauthorized
    end
    JWTSessions.exp_time = 3600
    JWTSessions::Token.decode(refreshed_tokens[:access]).first
    assert_equal EXPECTED_KEYS, refreshed_tokens.keys.sort
    assert_equal payload[:test], decoded_access['test']
  end
end
