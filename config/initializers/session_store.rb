# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_eBento_session',
  :secret      => '4c94dde46fd67d0a8fe03af24f74f7ca6838b6d3412a410b2a3f0f1ad8e25f33fb683ecd1a8fdb3b4c8cd1d3b0bba5baf156a3131997d230a5eb6304435896da'  
  
  }
# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
