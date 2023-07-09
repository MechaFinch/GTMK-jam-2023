package sprite;

import java.awt.image.BufferedImage;
import java.io.FileOutputStream;
import java.io.IOException;
import java.nio.file.DirectoryStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

import javax.imageio.ImageIO;

import asmlib.util.relocation.RelocatableObject;
import asmlib.util.relocation.RelocatableObject.Endianness;
import util.Pair;

/**
 * Converts a folder of BMP files to a relocatable object file
 * 
 * Each sprite receives a reference with its file name
 * The library name is the name of the folder
 * 
 * Sprite Format:
 * offset   type        value
 * 0        u16         width
 * 2        u16         height
 * 4        u8 array    raster data
 * 
 * @author Mechafinch
 */
public class SpriteConverter {
    public static void main(String[] args) throws IOException {
        Path spriteFolder = Paths.get(args[0]),
             paletteFile = Paths.get(args[1]),
             paletteName = Paths.get(args[2]),
             outputFile = Paths.get(args[3]);
        
        if(!Files.isDirectory(spriteFolder)) {
            throw new IllegalArgumentException("Please provide a directory");
        }
        
        // read palette
        RelocatableObject paletteObject = new RelocatableObject(paletteFile.toFile());
        byte[] rawPalette = paletteObject.getObjectCode();
        
        Map<Integer, Byte> palette = new HashMap<>();
        for(int i = 1; i < 256; i++) {
            byte r = rawPalette[i*3 + 2],
                 g = rawPalette[i*3 + 1],
                 b = rawPalette[i*3 + 0];
            
            int argb = 0xFF_00_00_00 | ((r & 0xFF) << 16) | ((g & 0xFF) << 8) | (b & 0xFF);
            
            palette.putIfAbsent(argb, (byte) i);
        }
        
        // RO parts
        HashMap<String, List<Integer>> incomingReferences = new HashMap<>();
        HashMap<String, Integer> outgoingReferences = new HashMap<>(),
                                 incomingReferenceWidths = new HashMap<>(),
                                 outgoingReferenceWidths = new HashMap<>();
        List<Byte> objectCodeList = new ArrayList<>();
        
        try(DirectoryStream<Path> ds = Files.newDirectoryStream(spriteFolder)) {
            for(Path p : ds) {
                if(Files.isDirectory(p)) continue;
                
                // convert and add
                try {
                    System.out.println("Converting " + p);
                    
                    Pair<String, List<Byte>> data = convert(p, palette);
                    
                    System.out.println("Created sprite " + data.a() + " from " + p);
                    
                    int offset = objectCodeList.size();
                    outgoingReferences.put(data.a(), offset);
                    outgoingReferenceWidths.put(data.a(), 4);
                    
                    objectCodeList.addAll(data.b());
                } catch(IOException e) {
                    e.printStackTrace();
                }
            }
        }
        
        // get to array
        byte[] objectCode = new byte[objectCodeList.size()];
        
        for(int i = 0; i < objectCode.length; i++) {
            objectCode[i] = objectCodeList.get(i);
        }
        
        // write
        RelocatableObject finalObject = new RelocatableObject(Endianness.LITTLE, spriteFolder.getFileName().toString(), 4, incomingReferences, outgoingReferences, incomingReferenceWidths, outgoingReferenceWidths, objectCode, false);
        
        try(FileOutputStream fos = new FileOutputStream(outputFile.toFile())) {
            fos.write(finalObject.asObjectFile());
        }
    }
    
    private static Pair<String, List<Byte>> convert(Path p, Map<Integer, Byte> palette) throws IOException {
        BufferedImage img = ImageIO.read(p.toFile());
        
        int w = img.getWidth(),
            ow = w,
            h = img.getHeight();
        
        // make sure width is a multiple of 4
        if((w & 3) != 0) {
            w = (w & ~3) + 4;
        }
        
        List<Byte> data = new ArrayList<>((w * h) + 4);
        data.add((byte)(w & 0xFF));
        data.add((byte)((w >> 8) & 0xFF));
        data.add((byte)(h & 0xFF));
        data.add((byte)((h >> 8) & 0xFF));
        
        Set<Integer> badColors = new HashSet<>();
        
        for(int y = 0; y < h; y++) {
            for(int x = 0; x < w; x++) {
                if(x >= ow) {
                    data.add((byte) 0);
                } else {
                    int argb = img.getRGB(x, y);
                    byte alpha = (byte)((argb >> 24) & 0xFF),
                         red = (byte)((argb >> 16) & 0xFF),
                         green = (byte)((argb >> 8) & 0xFF),
                         blue = (byte)(argb & 0xFF);
                    
                    //System.out.printf("%02X %02X %02X %02X%n", alpha, red, green, blue);
                    
                    if(alpha != (byte) 0xFF) {
                        // transparent
                        data.add((byte) 0);
                    } else {
                        // index
                        Byte b = palette.get(argb);
                        
                        if(b == null) {
                            if(!badColors.contains(argb)) {
                                System.out.println("Color not in palette: " + Integer.toHexString(argb));
                                badColors.add(argb);
                            }
                            
                            data.add((byte) 0);
                        } else {
                            data.add(b);
                        }
                    }
                }
            }
        }
        
        if(data.size() < (w * h) + 4) throw new IllegalStateException("Missing data: expected " + ((w * h) + 4) + " got " + data.size());
        
        String name = p.getFileName().toString();
        name = name.substring(0, name.lastIndexOf('.'));
        
        return new Pair<>(name, data);
    }
}
