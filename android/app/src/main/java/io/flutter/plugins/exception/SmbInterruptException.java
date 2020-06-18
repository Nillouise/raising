package io.flutter.plugins.exception;


import net.sf.sevenzipjbinding.SevenZipException;

public class SmbInterruptException extends RuntimeException {
    public SmbInterruptException(String message) {
        super(message);
    }
}
