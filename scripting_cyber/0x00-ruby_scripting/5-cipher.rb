#!/usr/bin/env ruby

class CaesarCipher
  def initialize(shift)
    @shift = shift
  end

  def encrypt(message)
    cipher(message, @shift)
  end

  def decrypt(message)
    cipher(message, -@shift)
  end

  private

  def cipher(message, shift)
    result = ""

    message.each_char do |char|
      if char >= 'A' && char <= 'Z'
        base = 'A'.ord
        result += ((char.ord - base + shift) % 26 + base).chr
      elsif char >= 'a' && char <= 'z'
        base = 'a'.ord
        result += ((char.ord - base + shift) % 26 + base).chr
      else
        result += char
      end
    end

    result
  end
end
