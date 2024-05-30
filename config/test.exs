# Streamline logger output to just the message for easier testing
Logger.configure_backend :console,
  level: :info,
  format: "$message\n",
  colors: [enabled: false]
