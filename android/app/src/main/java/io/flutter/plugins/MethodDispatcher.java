package io.flutter.plugins;


import android.os.Handler;
import android.os.Looper;
import android.os.AsyncTask;
import android.util.Log;

import com.orhanobut.logger.Logger;

import org.apache.commons.lang3.exception.ExceptionUtils;
import org.jetbrains.annotations.NotNull;

import java.util.ArrayList;
import java.util.HashMap;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;
import io.flutter.plugins.exception.SmbException;

public class MethodDispatcher implements MethodCallHandler {

    /**
     * Plugin registration.
     */
//    public static void registerWith(Registrar registrar) {
//        final MethodChannel channel = new MethodChannel(registrar.messenger(), "tesseract_ocr");
//        channel.setMethodCallHandler(new MethodDispatcher());
//    }

    // MethodChannel.Result wrapper that responds on the platform thread.
    private static class MethodResultWrapper implements Result {
        private Result methodResult;
        private Handler handler;

        MethodResultWrapper(Result result) {
            methodResult = result;
            handler = new Handler(Looper.getMainLooper());
        }

        @Override
        public void success(final Object result) {
            handler.post(new Runnable() {
                @Override
                public void run() {
                    methodResult.success(result);
                }
            });
        }

        @Override
        public void error(final String errorCode, final String errorMessage, final Object errorDetails) {
            handler.post(new Runnable() {
                @Override
                public void run() {
                    methodResult.error(errorCode, errorMessage, errorDetails);
                }
            });
        }

        @Override
        public void notImplemented() {
            handler.post(new Runnable() {
                @Override
                public void run() {
                    methodResult.notImplemented();
                }
            });
        }
    }

    @Override
    public void onMethodCall(MethodCall call, @NotNull Result rawResult) {

        Result result = new MethodResultWrapper(rawResult);
        Log.i("onMethodCall", call.method.toString() + call.arguments);
        Smb smb = new Smb(
                call.argument("hostname"),
                call.argument("shareName"),
                call.argument("domain"),
                call.argument("username"),
                call.argument("password"),
                call.argument("path"),
                call.argument("searchPattern")
        );
        if (call.method.equals("smbList")) {
            new Thread(
                    () -> {
                        try {
                            ArrayList<String> res = new Smb().listFile(call.argument("hostname"),
                                    call.argument("shareName"),
                                    call.argument("domain"),
                                    call.argument("username"),
                                    call.argument("password"),
                                    call.argument("path"),
                                    call.argument("searchPattern"));
                            result.success(res);
                        } catch (Exception e) {
                            Log.i("SMB", ExceptionUtils.getStackTrace(e));
                            result.error("smbList", e.toString(), ExceptionUtils.getStackTrace(e));
                        }
                    }
            ).start();
        } else if (call.method.equals("getFile")) {
            new Thread(
                    () -> {
                        try {
                            byte[] res = null;
                            res = new Smb().getFile(call.argument("hostname"),
                                    call.argument("shareName"),
                                    call.argument("domain"),
                                    call.argument("username"),
                                    call.argument("password"),
                                    call.argument("path"),
                                    call.argument("searchPattern"));
                            result.success(res);
                        } catch (Exception e) {
                            Log.i("SMB", ExceptionUtils.getStackTrace(e));
                            result.error("getFile", e.toString(), ExceptionUtils.getStackTrace(e));
                        }
                    }
            ).start();
        } else if (call.method.equals("listZip")) {
            new Thread(
                    () -> {
                        try {
                            byte[] res = null;
                            res = new Smb().processShare(
                                    call.argument("hostname"),
                                    call.argument("shareName"),
                                    call.argument("domain"),
                                    call.argument("username"),
                                    call.argument("password"),
                                    call.argument("path"),
                                    call.argument("searchPattern")
                                    , share -> {
                                        try {
                                            Smb.listZip(call.argument("path"), share);
                                        } catch (SmbException e) {
                                            Logger.e("{}", ExceptionUtils.getStackTrace(e));
                                            throw new RuntimeException(e);
                                        }
                                        return null;
                                    }
                            );
                            result.success(null);
                        } catch (Exception e) {
                            Logger.i("SMB", ExceptionUtils.getStackTrace(e));
                            result.error("getFile", e.toString(), ExceptionUtils.getStackTrace(e));
                        }
                    }
            ).start();
        } else if (call.method.equals("previewFiles")) {
            new Thread(
                    () -> {
                        try {
                            HashMap<String, byte[]> res = smb.processShare(share -> {
                                        try {
                                            return smb.previewFile(call.argument("filenames"), share);
                                        } catch (SmbException e) {
                                            Logger.e("{}", ExceptionUtils.getStackTrace(e));
                                            throw new RuntimeException(e);
                                        }
                                    }
                            );
                            Logger.i("previewFiles res {}",res);
                            result.success(res);
                        } catch (Exception e) {
                            Logger.i("SMB", ExceptionUtils.getStackTrace(e));
                            result.error("getFile", e.toString(), ExceptionUtils.getStackTrace(e));
                        }
                    }
            ).start();
        } else {
            result.notImplemented();
        }
    }


}

//    private void calculateResult(final String tessDataPath, final String imagePath, final String language,
//                                 final Result result) {
//
//        new AsyncTask<Void, Void, Void>() {
//            @Override
//            protected Void doInBackground(Void... params) {
//
//                result.success(recognizedText[0]);
//                return null;
//            }
//
//            @Override
//            protected void onPostExecute(Void result) {
//                super.onPostExecute(result);
//            }
//        }.execute();
//    }

