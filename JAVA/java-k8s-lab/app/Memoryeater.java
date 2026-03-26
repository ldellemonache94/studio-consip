import java.util.ArrayList;
import java.util.List;

public class MemoryEater {
    public static void main(String[] args) throws Exception {
        List<byte[]> memory = new ArrayList<>();

        while (true) {
            memory.add(new byte[10 * 1024 * 1024]); // 10MB
            System.out.println("Allocated: " + memory.size() * 10 + " MB");
            Thread.sleep(1000);
        }
    }
}