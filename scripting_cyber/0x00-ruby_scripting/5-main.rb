require_relative '5-cipher'


cipher = CaesarCipher.new(5)

# Encrypting a message
plaintext = "Hello, Holberton!"
encrypted_message = cipher.encrypt(plaintext)
puts "Encrypted message: #{encrypted_message}"

# Decrypting the encrypted message
decrypted_message = cipher.decrypt(encrypted_message)
puts "Decrypted message: #{decrypted_message}"
