export type LampiS3Event = {
  s3SchemaVersion: string;
  configurationId: string;
  bucket: {
    name: string;
    ownerIdentity: {
      principalId: string;
    };
    arn: string;
  };
  object: {
    key: string;
    size: number;
    eTag: string;
    versionId?: string | undefined;
    sequencer: string;
  };
};

export type LampiEvent = {
  token: string;
  s3: LampiS3Event;
};

export type Tiedosto = {
  lampiKey: string;
  ovaraKeyTemplate: string;
  batchSize: number;
};

export type Tiedostot = {
  [tiedosto: string]: Tiedosto;
};

export const tiedostot: Tiedostot = {
  koodisto_koodi: {
    lampiKey: 'fulldump/koodisto/v2/json/koodi.json',
    ovaraKeyTemplate: 'koodisto/koodisto_koodi__{}__{}_{}.json',
    batchSize: 250000,
  },
  koodisto_relaatio: {
    lampiKey: 'fulldump/koodisto/v2/json/relaatio.json',
    ovaraKeyTemplate: 'koodisto/koodisto_relaatio__{}__{}_{}.json',
    batchSize: 250000,
  },
  onr_henkilo: {
    lampiKey: 'fulldump/oppijanumerorekisteri/v2/json/henkilo.json',
    ovaraKeyTemplate: 'onr/onr_henkilo__{}__{}_{}.json',
    batchSize: 500000,
  },
  onr_yhteystieto: {
    lampiKey: 'fulldump/oppijanumerorekisteri/v2/json/yhteystieto.json',
    ovaraKeyTemplate: 'onr/onr_yhteystieto__{}__{}_{}.json',
    batchSize: 100000,
  },
  organisaatio_organisaatio: {
    lampiKey: 'fulldump/organisaatio/v2/json/organisaatio.json',
    ovaraKeyTemplate: 'organisaatio/organisaatio_organisaatio__{}__{}_{}.json',
    batchSize: 50000,
  },
  organisaatio_organisaatiosuhde: {
    lampiKey: 'fulldump/organisaatio/v2/json/organisaatiosuhde.json',
    ovaraKeyTemplate: 'organisaatio/organisaatio_organisaatiosuhde__{}__{}_{}.json',
    batchSize: 5000,
  },
  organisaatio_osoite: {
    lampiKey: 'fulldump/organisaatio/v2/json/osoite.json',
    ovaraKeyTemplate: 'organisaatio/organisaatio_osoite__{}__{}_{}.json',
    batchSize: 50000,
  },
  organisaatio_ryhma: {
    lampiKey: 'fulldump/organisaatio/v3/json/ryhma.json',
    ovaraKeyTemplate: 'organisaatio/organisaatio_ryhma__{}__{}_{}.json',
    batchSize: 20000,
  },
};

export const tiedostotyyppiByLampiKey = (lampiKey: string): string => {
  const tiedostotyyppi: string | undefined = Object.keys(tiedostot).find((tt) => {
    const t = tiedostot[tt];
    return t.lampiKey === lampiKey;
  });
  if (!tiedostotyyppi) {
    const message = `Tuntematon Lampi-tiedosto: ${lampiKey}`;
    console.error(message);
    throw Error(message);
  }
  return tiedostotyyppi;
};

const disabledLampiKeys = ['fulldump/oppijanumerorekisteri/v2/json/henkilo.json'];

export const lampiKeyExists = (lampiKey: string) => {
  if (disabledLampiKeys.includes(lampiKey)) return false;
  return Object.values(tiedostot).some(
    (tiedosto: Tiedosto) => tiedosto.lampiKey === lampiKey
  );
};
