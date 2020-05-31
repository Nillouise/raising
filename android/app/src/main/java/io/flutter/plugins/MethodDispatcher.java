package io.flutter.plugins;


import android.os.Handler;
import android.os.Looper;

import com.orhanobut.logger.Logger;

import org.apache.commons.lang3.exception.ExceptionUtils;
import org.jetbrains.annotations.NotNull;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

public class MethodDispatcher implements MethodCallHandler {

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


    //    private ConcurrentLinkedQueue<String> previewFileQueue = new ConcurrentLinkedQueue<>();
    private ExecutorService executorService = Executors.newFixedThreadPool(4);

    //一次只会处理一个smb链接
    private Smb smb;

    @Override
    public void onMethodCall(MethodCall call, @NotNull Result rawResult) {
        Result result = new MethodResultWrapper(rawResult);
        if (call.method.equals("init")) {
            smb = new Smb(
                    call.argument("hostname"),
                    call.argument("shareName"),
                    call.argument("domain"),
                    call.argument("username"),
                    call.argument("password"),
                    call.argument("path"),
                    call.argument("searchPattern")
            );
            result.success(null);
        } else if (call.method.equals("listFiles")) {
            executorService.submit(() -> {
                try {
                    ArrayList<String> res = smb.listFiles(
                            call.argument("path"),
                            call.argument("searchPattern"));
                    result.success(res);
                } catch (Exception e) {
                    result.error("listFiles", e.toString(), ExceptionUtils.getStackTrace(e));
                }
            });
//        } else if (call.method.equals("getFile")) {
//            new Thread(
//                    () -> {
//                        try {
//                            byte[] res = null;
//                            res = new Smb().getFile(call.argument("hostname"),
//                                    call.argument("shareName"),
//                                    call.argument("domain"),
//                                    call.argument("username"),
//                                    call.argument("password"),
//                                    call.argument("path"),
//                                    call.argument("searchPattern"));
//                            result.success(res);
//                        } catch (Exception e) {
//                            Logger.e("SMB %s", ExceptionUtils.getStackTrace(e));
//                            result.error("getFile", e.toString(), e);
//                        }
//                    }
//            ).start();
        } else if (call.method.equals("listContent")) {
            executorService.submit(() -> {
                try {
                    String res = smb.processShare(
                            share -> {
                                return smb.listContent(call.argument("absoluteFilename"), share);
                            }
                    );
                    result.success(res);
                } catch (Exception e) {
                    result.error("listContent", e.toString(), e);
                }
            });
        } else if (call.method.equals("previewFiles")) {
            executorService.submit(() -> {
                try {
                    HashMap<String, byte[]> res = smb.processShare(share -> {
                                return smb.previewFile(call.argument("absFilenames"), share);
                            }
                    );
                    result.success(res);
                } catch (Exception e) {
                    result.error("previewFiles", e.toString(), e);
                }
            });
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

