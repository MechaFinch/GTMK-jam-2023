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
import java.util.List;

import javax.imageio.ImageIO;

import asmlib.util.relocation.RelocatableObject;
import asmlib.util.relocation.RelocatableObject.Endianness;
import util.Pair;

/**
 * Converts a set of palette images to a relocatable object file
 * Each palette recieves a reference with its file name
 * The library name is the name of the folder
 * 
 * @author Mechafinch
 */
public class PaletteConverter {
    public static void main(String[] args) throws IOException {
        Path paletteFolder = Paths.get(args[0]),
             outputFile = Paths.get(args[1]);
        
        if(!Files.isDirectory(paletteFolder)) {
            throw new IllegalArgumentException("Please provide a directory");
        }
        
        // RO parts
        HashMap<String, List<Integer>> incomingReferences = new HashMap<>();
        HashMap<String, Integer> outgoingReferences = new HashMap<>(),
                                 incomingReferenceWidths = new HashMap<>(),
                                 outgoingReferenceWidths = new HashMap<>();
        List<Byte> objectCodeList = new ArrayList<>();
        
        try(DirectoryStream<Path> ds = Files.newDirectoryStream(paletteFolder)) {
            for(Path p : ds) {
                if(Files.isDirectory(p)) continue;
                
                // convert and add
                try {
                    System.out.println("Converting " + p);
                    
                    Pair<String, List<Byte>> data = convert(p);
                    
                    System.out.println("Created palette " + data.a() + " from " + p);
                    
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
        RelocatableObject finalObject = new RelocatableObject(Endianness.LITTLE, paletteFolder.getFileName().toString(), 2, incomingReferences, outgoingReferences, incomingReferenceWidths, outgoingReferenceWidths, objectCode, false);
        
        try(FileOutputStream fos = new FileOutputStream(outputFile.toFile())) {
            fos.write(finalObject.asObjectFile());
        }
    }
    
    /**
     * Converts the given file to a palette RO
     * 
     * @param p
     * @return
     * @throws IOException 
     */
    private static Pair<String, List<Byte>> convert(Path p) throws IOException {
        BufferedImage img = ImageIO.read(p.toFile());
        List<Byte> data = new ArrayList<>(256 * 3);
        
        // pad index 0 for transparency
        data.add((byte) 0);
        data.add((byte) 0);
        data.add((byte) 0);
        
        int w = img.getWidth(),
            h = img.getHeight();
        
        if(w * h < 256) throw new IllegalArgumentException("Invalid palette image: must be at least 256 pixels");
        
        out:
        for(int y = 0; y < h; y++) {
            for(int x = 0; x < w; x++) {
                int i = (y * w) + x + 1;
                
                if(i >= 256) break out;
                
                int argb = img.getRGB(x, y);
                byte alpha = (byte)((argb >> 24) & 0xFF),
                     red = (byte)((argb >> 16) & 0xFF),
                     green = (byte)((argb >> 8) & 0xFF),
                     blue = (byte)(argb & 0xFF);
                
                //System.out.printf("%02X %02X %02X %02X%n", alpha, red, green, blue);
                
                data.add(blue);
                data.add(green);
                data.add(red);
            }
        }
        
        String name = p.getFileName().toString();
        name = name.substring(0, name.lastIndexOf('.'));
        
        return new Pair<>(name, data);
    }
}
