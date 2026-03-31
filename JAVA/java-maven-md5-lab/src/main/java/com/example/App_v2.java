package com.example;

/**
 * Classe principale dell'applicazione.
 * VERSIONE 2 - Aggiunto metodo farewell e messaggio esteso.
 */
public class App {

    /**
     * Genera un messaggio di saluto.
     *
     * @param name il nome da salutare
     * @return stringa di saluto
     */
    public String greet(String name) {
        return "Hello, " + name + "! Welcome to the MD5 demo.";
    }

    /**
     * Genera un messaggio di congedo.
     *
     * @param name il nome
     * @return stringa di congedo
     */
    public String farewell(String name) {
        return "Goodbye, " + name + "! See you soon.";
    }

    public static void main(String[] args) {
        App app = new App();
        System.out.println(app.greet("World"));
        System.out.println(app.farewell("World"));
    }
}
