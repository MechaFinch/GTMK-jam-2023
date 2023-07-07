package sprite;

import java.awt.image.BufferedImage;
import java.io.FileOutputStream;
import java.io.IOException;
import java.nio.file.DirectoryStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.HashMap;
import java.util.List;

import javax.imageio.ImageIO;

import asmlib.util.relocation.RelocatableObject;

/**
 * Converts a set of palette images to a relocatable object file
 * Each palette recieves a reference with its file name
 * 
 * @author Mechafinch
 */
public class PaletteConverter {
    public static void main(String[] args) throws IOException {
        Path paletteFolder = Paths.get(args[0]);
        
        if(!Files.isDirectory(paletteFolder)) {
            throw new IllegalArgumentException("Please provide a directory");
        }
        
        // RO parts
        HashMap<String, List<Integer>> incomingReferences = new HashMap<>();
        HashMap<String, Integer> outgoingReferences = new HashMap<>(),
                                 incomingReferenceWidths = new HashMap<>(),
                                 outgoingReferenceWidths = new HashMap<>();
        
        try(DirectoryStream<Path> ds = Files.newDirectoryStream(paletteFolder)) {
            for(Path p : ds) {
                if(Files.isDirectory(p)) continue;
                
                RelocatableObject obj = convert(p);
            }
        }
    }
    
    /**
     * Converts the given file to a palette RO
     * 
     * @param p
     * @return
     */
    private static RelocatableObject convert(Path p) {
        return null; // TODO
    }
}
