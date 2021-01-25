package util;

import java.io.PrintStream;
import java.io.StreamTokenizer;
import java.util.Properties;
import java.util.StringTokenizer;

import javax.activation.DataHandler;
import javax.activation.FileDataSource;
import javax.mail.*;
import javax.mail.internet.*;

public class MailUtil
{

    public MailUtil()
    {
    }

    public static void SendMail(String sHost, String sFrom, String sTo, String sSubject, String sContentType, String sContent)
        throws Exception
    {
        String host = sHost;
        String from = sFrom;
        String to = sTo;
        try
        {
            Properties props = System.getProperties();
            props.put("mail.smtp.host", host);
            Session session = Session.getDefaultInstance(props, null);
            MimeMessage message = new MimeMessage(session);
            message.setFrom(new InternetAddress(from));
            message.addRecipient(javax.mail.Message.RecipientType.TO, new InternetAddress(to));
            message.setSubject(sSubject);
            
            if (sContentType.equalsIgnoreCase("HTML"))
       	     message.setContent(sContent,"text/html");
       	    else message.setContent(sContent,"text/plain");
                       
            Transport.send(message);
        }
        catch(Exception e)
        {
            System.out.println("Error in MailUtil(normal): " + e.getMessage());
        }
    }

    public static void SendMail(String sHost, String sFrom, String sTo, String sCC, String sSubject, String sContentType, String sContent)
        throws Exception
    {
        String host = sHost;
        String from = sFrom;
        
        // The following lines are temporarily commented. After the JAVA environment
        // is upgraded, then, we can use the split method.
        //String to[]= sTo.split(",");     
        //String cc[]= sCC.split(",");
        
        String[] to=new String[100];
        String[] cc=new String[100];
        StringTokenizer st;
        int idx=0;
        
        st = new StringTokenizer(sTo, ",");
        idx=0;
        while (st.hasMoreTokens()) 
        {
            String strTo = st.nextToken();
            to[idx]=strTo;
            idx++;
        }
        if (idx==0) to[0]=sTo;
        
        st = new StringTokenizer(sCC, ",");
        idx=0;
        while (st.hasMoreTokens()) 
        {
            String strCC = st.nextToken();
            cc[idx]=strCC;
            idx++;
        }
        if (idx==0) cc[0]=sCC;
                               
        try
        {
            int i = 0;
            Properties props = System.getProperties();
            props.put("mail.smtp.host", host);
            Session session = Session.getDefaultInstance(props, null);
            MimeMessage message = new MimeMessage(session);
            message.setFrom(new InternetAddress(from));
            for(i = 0; i < to.length; i++)
            {
              if (to[i] !=null && to[i].length() >0)
                message.addRecipient(javax.mail.Message.RecipientType.TO, new InternetAddress(to[i]));
            }

            for(i = 0; i < cc.length; i++)
            {
                if (cc[i] !=null && cc[i].length() >0)
                message.addRecipient(javax.mail.Message.RecipientType.CC, new InternetAddress(cc[i]));
            }

            message.setSubject(sSubject);
            if (sContentType.equalsIgnoreCase("HTML"))
          	     message.setContent(sContent,"text/html");
          	    else message.setContent(sContent,"text/plain");
                          
            Transport.send(message);
        }
        catch(Exception e)
        {
            System.out.println("Error in MailUtil(cc): " + e.getMessage());
        }
    }

    public static void SendMailAttachment(String sHost, String sFrom, String sTo, String sSubject, String sContent, String sAttachment)
        throws Exception
    {
        String host = sHost;
        String from = sFrom;
        String to = sTo;
        String fileAttachment = sAttachment;
        try
        {
            Properties props = System.getProperties();
            props.put("mail.smtp.host", host);
            Session session = Session.getInstance(props, null);
            MimeMessage message = new MimeMessage(session);
            message.setFrom(new InternetAddress(from));
            message.addRecipient(javax.mail.Message.RecipientType.TO, new InternetAddress(to));
            message.setSubject(sSubject);
            MimeBodyPart messageBodyPart = new MimeBodyPart();
            messageBodyPart.setText(sContent);
            Multipart multipart = new MimeMultipart();
            multipart.addBodyPart(messageBodyPart);
            messageBodyPart = new MimeBodyPart();
            javax.activation.DataSource source = new FileDataSource(fileAttachment);
            messageBodyPart.setDataHandler(new DataHandler(source));
            messageBodyPart.setFileName(fileAttachment);
            multipart.addBodyPart(messageBodyPart);
            message.setContent(multipart);
            Transport.send(message);
        }
        catch(Exception e)
        {
            System.out.println("Error in MailUtil(Attach): " + e.getMessage());
        }
    }

    public void SendMailAttachment(String sHost, String sFrom, String sTo, String sReply, String sCC, String sBCC, String sSubject, 
            String sContent, String sAttachment, String sAttachmentName)
        throws Exception
    {
        String host = sHost;
        String from = sFrom;
        String to = sTo;
        String fileAttachment = sAttachment;
        try
        {
            Properties props = System.getProperties();
            props.put("mail.smtp.host", host);
            Session session = Session.getInstance(props, null);
            MimeMessage message = new MimeMessage(session);
            message.setFrom(new InternetAddress(from));
            message.addRecipient(javax.mail.Message.RecipientType.TO, new InternetAddress(to));
            message.setSubject(sSubject);
            message.setReplyTo(new InternetAddress[] {
                new InternetAddress(sReply)
            });
            message.addRecipient(javax.mail.Message.RecipientType.CC, new InternetAddress(sCC));
            message.addRecipient(javax.mail.Message.RecipientType.BCC, new InternetAddress(sBCC));
            MimeBodyPart messageBodyPart = new MimeBodyPart();
            messageBodyPart.setText(sContent);
            Multipart multipart = new MimeMultipart();
            multipart.addBodyPart(messageBodyPart);
            messageBodyPart = new MimeBodyPart();
            javax.activation.DataSource source = new FileDataSource(fileAttachment);
            messageBodyPart.setDataHandler(new DataHandler(source));
            messageBodyPart.setFileName(sAttachmentName);
            multipart.addBodyPart(messageBodyPart);
            message.setContent(multipart);
            Transport.send(message);
        }
        catch(Exception e)
        {
            System.out.println("Error in MailUtil(Attach/bcc): " + e.getMessage());
        }
    }

    public void SendMailAttachment(String sHost, String sFrom, String sTo, String sSubject, String sContent, String sAttachment, String sAttachmentName)
        throws Exception
    {
        String host = sHost;
        String from = sFrom;
        String to = sTo;
        String fileAttachment = sAttachment;
        try
        {
            Properties props = System.getProperties();
            props.put("mail.smtp.host", host);
            Session session = Session.getInstance(props, null);
            MimeMessage message = new MimeMessage(session);
            message.setFrom(new InternetAddress(from));
            message.addRecipient(javax.mail.Message.RecipientType.TO, new InternetAddress(to));
            message.setSubject(sSubject);
            MimeBodyPart messageBodyPart = new MimeBodyPart();
            messageBodyPart.setText(sContent);
            Multipart multipart = new MimeMultipart();
            multipart.addBodyPart(messageBodyPart);
            messageBodyPart = new MimeBodyPart();
            javax.activation.DataSource source = new FileDataSource(fileAttachment);
            messageBodyPart.setDataHandler(new DataHandler(source));
            messageBodyPart.setFileName(sAttachmentName);
            multipart.addBodyPart(messageBodyPart);
            message.setContent(multipart);
            Transport.send(message);
        }
        catch(Exception e)
        {
            System.out.println("Error in MailUtil(other): " + e.getMessage());
        }
    }
}