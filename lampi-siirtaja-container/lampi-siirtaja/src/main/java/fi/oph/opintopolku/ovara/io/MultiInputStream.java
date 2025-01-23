package fi.oph.opintopolku.ovara.io;

import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.util.Enumeration;
import java.util.Objects;
import java.util.function.Supplier;
import software.amazon.awssdk.core.ResponseInputStream;
import software.amazon.awssdk.services.s3.model.GetObjectResponse;

public class MultiInputStream extends InputStream {
  private final Enumeration<Supplier<ResponseInputStream<GetObjectResponse>>> e;
  private InputStream in;

  public MultiInputStream(Enumeration<Supplier<ResponseInputStream<GetObjectResponse>>> e) {
    this.e = e;
    peekNextStream();
  }

  final void nextStream() throws IOException {
    if (in != null) {
      in.close();
    }
    peekNextStream();
  }

  private void peekNextStream() {
    if (e.hasMoreElements()) {
      Supplier<ResponseInputStream<GetObjectResponse>> s = e.nextElement();
      in = s.get();
      if (in == null) throw new NullPointerException();
    } else {
      in = null;
    }
  }

  @Override
  public int available() throws IOException {
    if (in == null) {
      return 0; // no way to signal EOF from available()
    }
    return in.available();
  }

  @Override
  public int read() throws IOException {
    while (in != null) {
      int c = in.read();
      if (c != -1) {
        return c;
      }
      nextStream();
    }
    return -1;
  }

  @Override
  public int read(byte[] b, int off, int len) throws IOException {
    if (in == null) {
      return -1;
    } else if (b == null) {
      throw new NullPointerException();
    }
    Objects.checkFromIndexSize(off, len, b.length);
    if (len == 0) {
      return 0;
    }
    do {
      int n = in.read(b, off, len);
      if (n > 0) {
        return n;
      }
      nextStream();
    } while (in != null);
    return -1;
  }

  @Override
  public void close() throws IOException {
    IOException ioe = null;
    while (in != null) {
      try {
        in.close();
      } catch (IOException e) {
        if (ioe == null) {
          ioe = e;
        } else {
          ioe.addSuppressed(e);
        }
      }
      peekNextStream();
    }
    if (ioe != null) {
      throw ioe;
    }
  }

  @Override
  public long transferTo(OutputStream out) throws IOException {
    Objects.requireNonNull(out, "out");
    if (getClass() == MultiInputStream.class) {
      long transferred = 0;
      while (in != null) {
        if (transferred < Long.MAX_VALUE) {
          try {
            transferred = Math.addExact(transferred, in.transferTo(out));
          } catch (ArithmeticException ignore) {
            return Long.MAX_VALUE;
          }
        }
        nextStream();
      }
      return transferred;
    } else {
      return super.transferTo(out);
    }
  }
}
