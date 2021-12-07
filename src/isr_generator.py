# to generate ISRs
print("# generated by isr_generator.py")
print("# do not modify, regenerate this file")


for i in range(0, 256):
  print("isr"+str(i)+":")
  if not (i == 8 or i == 17 or (10 <= i and i <= 14)):
    print(" pushl $0")
  print(" pushl $"+str(i))
  print(" jmp trap_begin")

print()
print()

print("# isr table")
print(".data")
print(".global ISRs")
print("ISRs:")

for i in range(0, 256):
  print(" .long isr" + str(i))