package util;

import java.io.File;
import java.io.FileOutputStream;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;

import javax.sound.midi.MidiEvent;
import javax.sound.midi.MidiMessage;
import javax.sound.midi.MidiSystem;
import javax.sound.midi.Sequence;
import javax.sound.midi.ShortMessage;
import javax.sound.midi.Track;

import asmlib.util.relocation.RelocatableObject;
import asmlib.util.relocation.RelocatableObject.Endianness;

// stack overflow
public class Test {
    public static final int NOTE_ON = 0x90;
    public static final int NOTE_OFF = 0x80;
    public static final String[] NOTE_NAMES = {"C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"};

    public static void main(String[] args) throws Exception {
        List<Byte> data = new ArrayList<>();
        
        /*
         * format
         * 0: time0
         * 1: time1
         * 2: time2
         * 3: time3
         * 4: number
         * 5: velocity
         * 6: note on/off
         * 7: 0
         * time = 0 for EOF
         */
        
        Sequence sequence = MidiSystem.getSequence(new File("gmtk_jam_song_1.mid"));
        long mspt = 60000 / (180 * sequence.getResolution());

        int trackNumber = 0;
        for (Track track :  sequence.getTracks()) {
            trackNumber++;
            System.out.println("Track " + trackNumber + ": size = " + track.size());
            System.out.println();
            for (int i=0; i < track.size(); i++) { 
                MidiEvent event = track.get(i);
                System.out.print("@" + event.getTick() + " ");
                MidiMessage message = event.getMessage();
                if (message instanceof ShortMessage) {
                    ShortMessage sm = (ShortMessage) message;
                    System.out.print("Channel: " + sm.getChannel() + " ");
                    if (sm.getCommand() == NOTE_ON) {
                        int key = sm.getData1();
                        int octave = (key / 12)-1;
                        int note = key % 12;
                        String noteName = NOTE_NAMES[note];
                        int velocity = sm.getData2();
                        System.out.println("Note on, " + noteName + octave + " key=" + key + " velocity: " + velocity);
                        
                        // my stuff
                        long time_ms = event.getTick() * mspt;
                        time_ms = time_ms == 0 ? 1 : time_ms;
                        data.add((byte)(time_ms & 0xFF));
                        data.add((byte)((time_ms >> 8) & 0xFF));
                        data.add((byte)((time_ms >> 16) & 0xFF));
                        data.add((byte)((time_ms >> 24) & 0xFF));
                        data.add((byte) key);
                        data.add((byte) velocity);
                        data.add((byte) 1);
                        data.add((byte) 0);
                    } else if (sm.getCommand() == NOTE_OFF) {
                        int key = sm.getData1();
                        int octave = (key / 12)-1;
                        int note = key % 12;
                        String noteName = NOTE_NAMES[note];
                        int velocity = sm.getData2();
                        System.out.println("Note off, " + noteName + octave + " key=" + key + " velocity: " + velocity);
                        
                     // my stuff
                        long time_ms = event.getTick() * mspt;
                        data.add((byte)(time_ms & 0xFF));
                        data.add((byte)((time_ms >> 8) & 0xFF));
                        data.add((byte)((time_ms >> 16) & 0xFF));
                        data.add((byte)((time_ms >> 24) & 0xFF));
                        data.add((byte) key);
                        data.add((byte) velocity);
                        data.add((byte) 0);
                        data.add((byte) 0);
                    } else {
                        System.out.println("Command:" + sm.getCommand());
                    }
                } else {
                    System.out.println("Other message: " + message.getClass());
                }
            }

            System.out.println();
        }
        
        // RO parts
        HashMap<String, List<Integer>> incomingReferences = new HashMap<>();
        HashMap<String, Integer> outgoingReferences = new HashMap<>(),
                                 incomingReferenceWidths = new HashMap<>(),
                                 outgoingReferenceWidths = new HashMap<>();
        
        // EOF
        data.add((byte) 0);
        data.add((byte) 0);
        data.add((byte) 0);
        data.add((byte) 0);
        
        data.add((byte) 0);
        data.add((byte) 0);
        data.add((byte) 0);
        data.add((byte) 0);
        
        outgoingReferences.put("song1", 0);
        outgoingReferences.put("song2", data.size());
        outgoingReferenceWidths.put("song1", 4);
        outgoingReferenceWidths.put("song2", 4);
        
        sequence = MidiSystem.getSequence(new File("gmtk_jam_song_2.mid"));
        mspt = 60000 / (180 * sequence.getResolution());

        trackNumber = 0;
        for (Track track :  sequence.getTracks()) {
            trackNumber++;
            System.out.println("Track " + trackNumber + ": size = " + track.size());
            System.out.println();
            for (int i=0; i < track.size(); i++) { 
                MidiEvent event = track.get(i);
                System.out.print("@" + event.getTick() + " ");
                MidiMessage message = event.getMessage();
                if (message instanceof ShortMessage) {
                    ShortMessage sm = (ShortMessage) message;
                    System.out.print("Channel: " + sm.getChannel() + " ");
                    if (sm.getCommand() == NOTE_ON) {
                        int key = sm.getData1();
                        int octave = (key / 12)-1;
                        int note = key % 12;
                        String noteName = NOTE_NAMES[note];
                        int velocity = sm.getData2();
                        System.out.println("Note on, " + noteName + octave + " key=" + key + " velocity: " + velocity);
                        
                        // my stuff
                        long time_ms = event.getTick() * mspt;
                        time_ms = time_ms == 0 ? 1 : time_ms;
                        data.add((byte)(time_ms & 0xFF));
                        data.add((byte)((time_ms >> 8) & 0xFF));
                        data.add((byte)((time_ms >> 16) & 0xFF));
                        data.add((byte)((time_ms >> 24) & 0xFF));
                        data.add((byte) key);
                        data.add((byte) velocity);
                        data.add((byte) 1);
                        data.add((byte) 0);
                    } else if (sm.getCommand() == NOTE_OFF) {
                        int key = sm.getData1();
                        int octave = (key / 12)-1;
                        int note = key % 12;
                        String noteName = NOTE_NAMES[note];
                        int velocity = sm.getData2();
                        System.out.println("Note off, " + noteName + octave + " key=" + key + " velocity: " + velocity);
                        
                     // my stuff
                        long time_ms = event.getTick() * mspt;
                        data.add((byte)(time_ms & 0xFF));
                        data.add((byte)((time_ms >> 8) & 0xFF));
                        data.add((byte)((time_ms >> 16) & 0xFF));
                        data.add((byte)((time_ms >> 24) & 0xFF));
                        data.add((byte) key);
                        data.add((byte) velocity);
                        data.add((byte) 0);
                        data.add((byte) 0);
                    } else {
                        System.out.println("Command:" + sm.getCommand());
                    }
                } else {
                    System.out.println("Other message: " + message.getClass());
                }
            }

            System.out.println();
        }
        
        // EOF
        data.add((byte) 0);
        data.add((byte) 0);
        data.add((byte) 0);
        data.add((byte) 0);
        
        data.add((byte) 0);
        data.add((byte) 0);
        data.add((byte) 0);
        data.add((byte) 0);
        
        // get to array
        byte[] objectCode = new byte[data.size()];
        
        for(int i = 0; i < objectCode.length; i++) {
            objectCode[i] = data.get(i);
        }
        
        // write
        RelocatableObject finalObject = new RelocatableObject(Endianness.LITTLE, "music", 4, incomingReferences, outgoingReferences, incomingReferenceWidths, outgoingReferenceWidths, objectCode, false);
        
        try(FileOutputStream fos = new FileOutputStream("../game/src/music.obj")) {
            fos.write(finalObject.asObjectFile());
        }
    }
}