
with open("textbig.dat", "rb") as rf, open("textsmall.dat", "wb") as wf:
    # each character in the set
    for i in range(128):
        largebytes = rf.read(32)
        print(largebytes)
        smallbytes = []
        
        # large format
        # each byte holds 2 pixels; upper nybble is first pixel
        # if the nybble is 1, it is foreground
        # if the nybble is 0, it is background
        
        # small format
        # each byte holds 8 pixels; LSB is first pixel
        # shift right = get next pixel
        # 1 = foreground
        # 0 = background
        
        # each small byte
        for j in range(8):
            sb = 0
            
            print(largebytes[j * 4 : (j * 4) + 4])
            
            # for each big byte
            for k in range(4):
                bb = largebytes[(j * 4) + k]
                sb = (((sb >> 2) & 0x3F) | (((bb >> 4) & 0x01) << 6) | ((bb & 0x01) << 7)) & 0xFF
                #print(f"{sb:02X}")
            
            print(f"{sb:02X}")
            print()
            
            smallbytes.append(sb & 0xFF)
        
        wf.write(bytes(smallbytes))
    
    wf.flush()
    rf.close()
    wf.close()